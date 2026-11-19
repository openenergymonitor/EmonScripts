"""Run only the real settings-file installation block, without system changes.

Run with: python3 -m unittest discover -s tests -p 'test_install_settings.py' -v
Requires bash and PHP CLI. PHP parses the result with Emoncms' scanner mode.
"""

import json
import os
from pathlib import Path
import shlex
import shutil
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class InstallSettingsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.oem = self.root / "openenergymonitor"
        self.scripts = self.oem / "EmonScripts"
        shutil.copytree(ROOT / "defaults", self.scripts / "defaults")
        shutil.copytree(ROOT / "install", self.scripts / "install")
        self.www = self.root / "www"
        self.www.mkdir()
        self.settings = self.www / "settings.ini"
        self.values = {
            "openenergymonitor_dir": str(self.oem),
            "emoncms_dir": "/opt/emoncms",
            "emoncms_datadir": "/var/opt/emoncms",
            "emoncms_www": str(self.www),
            "mysql_user": "custom_sql_user",
            "mysql_password": "custom_sql_password",
            "mysql_database": "custom_database",
            "mqtt_user": "custom_mqtt_user",
            "mqtt_password": "custom_mqtt_password",
        }
        source = (ROOT / "install/emoncms_core.sh").read_text()
        self.block = source.split("# Copy and install emonpi.settings.ini\n", 1)[1]
        self.block = self.block.split("\nif [ ! -d $emoncms_datadir ]; then", 1)[0]

    def install(self, extra_env=None, umask="022"):
        # These are shell variables, as when load_config.sh sources config.ini.
        assignments = "\n".join(k + "=" + shlex.quote(v) for k, v in self.values.items())
        env = os.environ.copy()
        env.update(extra_env or {})
        return subprocess.run(
            ["bash", "-c", "umask " + umask + "\n" + assignments + "\n" + self.block],
            env=env, text=True, capture_output=True, check=False,
        )

    def parsed(self):
        result = subprocess.run(
            ["php", "-r", "echo json_encode(parse_ini_file($argv[1], true, INI_SCANNER_TYPED), JSON_THROW_ON_ERROR);", str(self.settings)],
            text=True, capture_output=True, check=True,
        )
        return json.loads(result.stdout)

    def assert_installed(self):
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(self.values["mysql_password"], result.stdout + result.stderr)
        self.assertNotIn(self.values["mqtt_password"], result.stdout + result.stderr)
        return self.parsed()

    def test_custom_sql_account(self):
        settings = self.assert_installed()
        self.assertEqual(settings["sql"]["username"], self.values["mysql_user"])
        self.assertEqual(settings["sql"]["password"], self.values["mysql_password"])
        self.assertEqual(settings["sql"]["database"], self.values["mysql_database"])

    def test_custom_mqtt_account(self):
        settings = self.assert_installed()
        self.assertEqual(settings["mqtt"]["user"], self.values["mqtt_user"])
        self.assertEqual(settings["mqtt"]["password"], self.values["mqtt_password"])

    def test_ini_special_characters_are_literal(self):
        for password in ['space & slash/~;# = []', 'quotes\'" and \\backslash\\', '${HOME}$USER', 'false', '00123', '']:
            with self.subTest(password=password):
                self.values["mysql_password"] = password
                self.values["mqtt_password"] = password
                result = self.install()
                self.assertEqual(result.returncode, 0, result.stderr)
                settings = self.parsed()
                self.assertEqual(settings["sql"]["password"], password)
                self.assertEqual(settings["mqtt"]["password"], password)
                self.settings.unlink()

    def test_paths_and_unrelated_settings(self):
        self.values["emoncms_dir"] = '/opt/energy & solar~"${HOME}\\'
        self.values["emoncms_datadir"] = '/data/energy & solar~"${HOME}\\'
        settings = self.assert_installed()
        self.assertEqual(settings["emoncms_dir"], self.values["emoncms_dir"])
        self.assertEqual(settings["openenergymonitor_dir"], str(self.oem))
        self.assertEqual(settings["feed"]["phpfina"]["datadir"], self.values["emoncms_datadir"] + "/phpfina/")
        self.assertEqual(settings["feed"]["phptimeseries"]["datadir"], self.values["emoncms_datadir"] + "/phptimeseries/")
        self.assertIs(settings["redis"]["enabled"], True)
        self.assertEqual(settings["redis"]["prefix"], "")
        self.assertEqual(settings["feed"]["engines_hidden"], "[0,6,10]")

    def test_shipped_default_accounts(self):
        self.values.update(mysql_user="emoncms", mysql_password="emonpiemoncmsmysql2016",
                           mysql_database="emoncms", mqtt_user="emonpi", mqtt_password="emonpimqtt2016")
        settings = self.assert_installed()
        self.assertEqual(settings["sql"]["password"], "emonpiemoncmsmysql2016")
        self.assertEqual(settings["mqtt"]["password"], "emonpimqtt2016")

    def test_existing_settings_unchanged(self):
        original = b"; existing local choices\n[mqtt]\npassword = 'keep-me'\n"
        self.settings.write_bytes(original)
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.settings.read_bytes(), original)

    def test_file_permissions_follow_umask(self):
        template_mode = stat.S_IMODE((self.scripts / "defaults/emoncms/emonpi.settings.ini").stat().st_mode)
        for mask in ["022", "002", "077"]:
            with self.subTest(umask=mask):
                result = self.install(umask=mask)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(stat.S_IMODE(self.settings.stat().st_mode), template_mode & ~int(mask, 8))
                self.settings.unlink()

    def test_php_failure_leaves_no_settings_and_can_retry(self):
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        php = fake_bin / "php"
        php.write_text("#!/bin/sh\nprintf 'partial output'\nexit 1\n")
        php.chmod(0o755)
        result = self.install({"PATH": str(fake_bin) + os.pathsep + os.environ["PATH"]})
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.settings.exists())
        self.assertEqual(list(self.www.iterdir()), [])
        self.assert_installed()

    def test_missing_template_does_not_install_empty_settings(self):
        (self.scripts / "defaults/emoncms/emonpi.settings.ini").unlink()
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.settings.exists())
        self.assertEqual(list(self.www.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
