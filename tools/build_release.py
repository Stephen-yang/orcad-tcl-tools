"""Build a reproducible, allowlisted release without local history or data."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FILES = (
    'compat.tcl', 'utils.tcl', 'show_properties.tcl', 'bulk_replace_part.tcl',
    'dnp_annotator.tcl', 'orcad_tools_menu.tcl', 'orcad_tools_autoload.tcl',
    'README.md', 'README.en.md', 'install.md', 'install.en.md',
    'usage.md', 'usage.en.md', 'RELEASE_NOTES.md', 'RELEASE_NOTES.en.md', 'LICENSE',
)


def main():
    output = ROOT / 'dist'
    output.mkdir(exist_ok=True)
    archive = output / 'orcad-tcl-tools-validated-17.4.zip'
    payloads = {}
    for name in FILES:
        content = (ROOT / name).read_text(encoding='utf-8-sig')
        # Only the generic documentation drive/path example is allowed.
        without_example = content.replace('D:/orcad-tcl-tools/', '')
        if re.search(r'(?i)(?:(?<![\w])[A-Z]:[/\\]|\\\\[^\s\\]+\\|[\w.+-]+@[\w.-]+\.[A-Z]{2,})', without_example):
            raise ValueError(f'Unexpected absolute path, UNC path or email in {name}')
        if re.search(r'(?i)https?://github\.com/|\b[0-9]{8}FN[0-9]{2}A\b', content):
            raise ValueError(f'Unexpected account URL or non-generic part data in {name}')
        copyright_owner = (ROOT / 'LICENSE').read_text(encoding='utf-8').splitlines()[2].split('2026 ', 1)[1]
        if name != 'LICENSE' and copyright_owner in content:
            raise ValueError(f'Personal byline outside mandatory license notice: {name}')
        payloads[name] = content.replace('\r\n', '\n').encode('utf-8')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
        for name, payload in payloads.items():
            info = zipfile.ZipInfo(f'orcad-tcl-tools/{name}', (2020, 1, 1, 0, 0, 0))
            info.create_system = 0
            info.external_attr = 0x20
            info.compress_type = zipfile.ZIP_DEFLATED
            bundle.writestr(info, payload)
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None
        assert set(bundle.namelist()) == {f'orcad-tcl-tools/{name}' for name in FILES}
        for name, payload in payloads.items():
            assert bundle.read(f'orcad-tcl-tools/{name}') == payload
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / (archive.name + '.sha256')).write_text(f'{digest}  {archive.name}\n', encoding='ascii')
    print(f'Built {archive.name}: {len(FILES)} allowlisted files; SHA-256 {digest}')


if __name__ == '__main__':
    main()
