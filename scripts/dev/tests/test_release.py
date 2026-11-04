import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('publisher', Path(__file__).resolve().parents[1] / 'release.py')
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        (self.root / 'VERSION').write_text('0.2.0\n')
        (self.root / 'CHANGELOG.md').write_text(
            '# Changelog\n\n## [0.2.0] - 2026-11-04\n\nNew workspace.\n\n'
            '## [0.1.0] - 2026-11-04\n\nOld notes.\n')
        self.asset = self.root / 'app.tar.gz'
        self.asset.write_bytes(b'archive')

    def test_notes_only_include_selected_version(self):
        self.assertEqual(publisher.release_metadata(self.root), ('0.2.0', 'New workspace.\n'))

    def test_rejects_unsafe_version(self):
        (self.root / 'VERSION').write_text('0.2.0; echo hello')
        with self.assertRaises(ValueError):
            publisher.release_metadata(self.root)

    def test_missing_changelog_entry(self):
        (self.root / 'VERSION').write_text('0.3.0')
        with self.assertRaises(ValueError):
            publisher.release_metadata(self.root)

    def test_empty_changelog_entry(self):
        (self.root / 'CHANGELOG.md').write_text('## [0.2.0] - 2026-11-04\n\n## [0.1.0] - 2026-11-04\nOld')
        with self.assertRaises(ValueError):
            publisher.release_metadata(self.root)

    @patch.object(publisher, 'command', return_value='abc')
    @patch.object(publisher, 'github')
    @patch.object(publisher.subprocess, 'run')
    def test_published_release_is_never_overwritten(self, run, api, command):
        api.return_value = {'draft': False, 'html_url': 'https://example.test/v0.2.0'}
        publisher.publish(self.root, 'owner/repo', [self.asset])
        run.assert_not_called()

    @patch.object(publisher, 'command', return_value='abc')
    @patch.object(publisher, 'github', side_effect=[None, [], {'object': {'type': 'commit', 'sha': 'different'}}])
    @patch.object(publisher.subprocess, 'run')
    def test_conflicting_tag_cannot_publish_wrong_binary(self, run, api, command):
        with self.assertRaises(ValueError):
            publisher.publish(self.root, 'owner/repo', [self.asset])
        run.assert_not_called()

    @patch.object(publisher, 'command', return_value='abc')
    @patch.object(publisher, 'github', side_effect=[None, [], None])
    @patch.object(publisher.subprocess, 'run')
    def test_new_release_is_published_only_after_upload(self, run, api, command):
        publisher.publish(self.root, 'owner/repo', [self.asset])
        calls = [call.args[0] for call in run.call_args_list]
        self.assertEqual([call[2] for call in calls], ['create', 'upload', 'edit'])
        self.assertIn('--draft', calls[0])
        self.assertIn('--target', calls[0])
        self.assertIn('--draft=false', calls[-1])
        self.assertTrue((self.root / 'build/release-notes.md').is_file())

    @patch.object(publisher, 'command', return_value='abc')
    @patch.object(publisher, 'github', side_effect=[None, [], None])
    @patch.object(publisher.subprocess, 'run')
    def test_failed_upload_keeps_release_unpublished(self, run, api, command):
        run.side_effect = [subprocess.CompletedProcess([], 0), subprocess.CalledProcessError(1, 'gh')]
        with self.assertRaises(subprocess.CalledProcessError):
            publisher.publish(self.root, 'owner/repo', [self.asset])
        self.assertEqual(run.call_count, 2)

    @patch.object(publisher, 'command', return_value='abc')
    @patch.object(publisher, 'github', side_effect=[{'draft': True}, {'object': {'type': 'commit', 'sha': 'abc'}}])
    @patch.object(publisher.subprocess, 'run')
    def test_matching_draft_can_resume(self, run, api, command):
        publisher.publish(self.root, 'owner/repo', [self.asset])
        self.assertEqual([call.args[0][2] for call in run.call_args_list], ['edit', 'upload', 'edit'])

    @patch.object(publisher, 'command', return_value='abc')
    @patch.object(publisher, 'github', side_effect=[None, [{'draft': True, 'tag_name': 'v0.2.0', 'target_commitish': 'abc'}], None])
    @patch.object(publisher.subprocess, 'run')
    def test_unpublished_draft_is_found_when_tag_endpoint_returns_404(self, run, api, command):
        publisher.publish(self.root, 'owner/repo', [self.asset])
        self.assertEqual([call.args[0][2] for call in run.call_args_list], ['edit', 'upload', 'edit'])
        api.assert_any_call('repos/owner/repo/releases?per_page=100&page=1')

    @patch.object(publisher.subprocess, 'run')
    def test_permission_error_is_not_treated_as_missing_release(self, run):
        run.return_value = subprocess.CompletedProcess([], 1, json.dumps({'status': '403'}), 'Forbidden')
        with self.assertRaises(RuntimeError):
            publisher.github('repos/owner/repo/releases/tags/v0.2.0')

    @patch.object(publisher.subprocess, 'run')
    def test_not_found_can_start_new_release(self, run):
        run.return_value = subprocess.CompletedProcess([], 1, json.dumps({'status': '404'}), 'Not Found')
        self.assertIsNone(publisher.github('repos/owner/repo/releases/tags/v0.2.0'))


if __name__ == '__main__':
    unittest.main()
