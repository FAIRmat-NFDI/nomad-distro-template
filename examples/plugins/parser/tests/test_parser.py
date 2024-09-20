import os.path
from nomad.client import parse, normalize_all

def test_parser():
    test_file = os.path.join(os.path.dirname(__file__), 'data', 'test.example-format.txt')
    entry_archive = parse(test_file)[0]
    normalize_all(entry_archive)

    assert entry_archive.data.pattern.tolist() == [
        [1.0, 0.0, 1.0], [1.0, 1.0, 1.0], [1.0, 0.0, 1.0]
    ]
