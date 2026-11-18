"""Exercise the updater's disk-space block without updating the host.

Run with: python3 -m unittest discover -s tests -v
BusyBox cases are skipped when busybox is not installed.
"""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


class UpdateDiskSpaceTest(unittest.TestCase):
    def run_check(self, df_body, available=None):
        script = (Path(__file__).resolve().parents[1]
                  / "update/service-runner-update.sh").read_text()
        # Run the actual block. The rest of the updater changes the system.
        block = script.split("# Find largest log file and remove\n", 1)[1]
        block = block.split('echo "Starting update', 1)[0]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, body in {
                "df": df_body,
                # Never run sudo, find or truncate against real log files.
                "sudo": 'printf "%s\\n" "$*" >> "$CALL_LOG"\n'
                        'if [ "$1" = find ]; then printf "100\\t/fake/log\\n"; fi\n',
            }.items():
                path = root / name
                path.write_text("#!/bin/sh\n" + body)
                path.chmod(0o755)
            env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                       CALL_LOG=str(root / "calls"), LC_ALL="C",
                       BLOCK_SIZE="1M", POSIXLY_CORRECT="1")
            result = subprocess.run(
                ["bash", "-c", block + '\nprintf "AVAILABLE=%s\\n" "$varlog_available"'],
                env=env, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            calls = (root / "calls").read_text() if (root / "calls").exists() else ""
            if available is not None:
                self.assertIn(f"AVAILABLE={available}\n", result.stdout)
            return result, calls

    def check_real_df(self, command):
        expected_env = dict(os.environ, LC_ALL="C")
        expected_env.pop("POSIXLY_CORRECT", None)
        expected_env.pop("BLOCK_SIZE", None)
        expected = subprocess.check_output(
            command + ["-Pk", "/var/log"], text=True,
            env=expected_env).splitlines()[-1].split()[3]
        result, calls = self.run_check("exec " + shlex.join(command) + ' "$@"\n')
        self.assertEqual(result.stderr, "")
        # Free space can change while the two commands run. Check the units
        # and accept modest concurrent writes, rather than requiring equality.
        actual = int(result.stdout.rsplit("AVAILABLE=", 1)[1].strip())
        self.assertLess(abs(actual - int(expected)), 10240)
        self.assertEqual(calls, "")

    def test_gnu_df_with_non_default_block_size(self):
        self.check_real_df([shutil.which("df")])

    @unittest.skipUnless(shutil.which("busybox"), "BusyBox not installed")
    def test_busybox_df(self):
        self.check_real_df([shutil.which("busybox"), "df"])

    def test_free_space_threshold(self):
        for free in (0, 1023, 1024, 2048):
            with self.subTest(free=free):
                # -P prevents long filesystem names wrapping onto two lines.
                body = ('[ "$1" = -Pk ] || exit 2\n'
                        "printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\\n"
                        f"/a/very/long/filesystem/name 4096 2048 {free} 50%% /var/log\\n'\n")
                result, calls = self.run_check(body, str(free))
                self.assertEqual(result.stderr, "")
                self.assertEqual("truncate -s 0 /fake/log" in calls, free < 1024)

    def test_df_failure_does_not_truncate_or_compare_an_empty_value(self):
        result, calls = self.run_check('echo "df: cannot read filesystem" >&2\nexit 1\n', "")
        self.assertIn("df: cannot read filesystem", result.stderr)
        self.assertNotIn("integer expression expected", result.stderr)
        self.assertEqual(calls, "")


if __name__ == "__main__":
    unittest.main()
