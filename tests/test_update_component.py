"""Exercise the updater with real local Git repositories and a fake PHP reply.

Regression for #204; no system installation or database is touched.
Run: python3 -m unittest discover -s tests -v
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class UpdateComponentTest(unittest.TestCase):
    def test_database_update_messages(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix="emon-update-") as tmp:
            tmp = Path(tmp)
            scripts = tmp / "EmonScripts"
            (scripts / "update").mkdir(parents=True)
            (scripts / "install").mkdir()
            for name in ("update_component.sh", "load_config.sh"):
                shutil.copy2(root / "update" / name, scripts / "update" / name)
            (scripts / "install" / "config.ini").write_text(
                "openenergymonitor_dir='%s'\nuser=test\n" % tmp)
            commands = tmp / "bin"
            commands.mkdir()
            php = commands / "php"
            php.write_text('#!/bin/sh\nprintf "%s\\n" "$DATABASE_REPLY"\n')
            php.chmod(0o755)
            env = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ["PATH"],
                       GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                       GIT_TERMINAL_PROMPT="0")

            def git(*args):
                return subprocess.run(["git", *map(str, args)], env=env,
                                      capture_output=True, text=True, check=True)

            remote = tmp / "remote.git"
            module = tmp / "module"
            git("init", "--bare", remote)
            git("clone", remote, module)
            git("-C", module, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                "commit", "--allow-empty", "-m", "fixture")
            git("-C", module, "branch", "-M", "stable")
            git("-C", module, "push", "-u", "origin", "stable")
            publisher = tmp / "publisher"
            git("clone", "--branch", "stable", remote, publisher)
            (publisher / "updated.txt").write_text("updated component\n")
            git("-C", publisher, "add", "updated.txt")
            git("-C", publisher, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                "commit", "-m", "component update")
            git("-C", publisher, "push")
            for reply in ("[]", '["Added field to table"]', '[\n "First update",\n "Second update"\n]', ""):
                with self.subTest(reply=reply):
                    result = subprocess.run(
                        ["bash", str(scripts / "update" / "update_component.sh"), str(module)],
                        env=dict(env, DATABASE_REPLY=reply), text=True, capture_output=True,
                        timeout=20)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertNotIn("too many arguments", result.stderr)
                    self.assertNotIn("unary operator expected", result.stderr)
                    expected = "no changes" if reply == "[]" else reply
                    self.assertIn("- database update: " + expected + "\n", result.stdout)
                    self.assertEqual((module / "updated.txt").read_text(), "updated component\n")


if __name__ == "__main__":
    unittest.main()
