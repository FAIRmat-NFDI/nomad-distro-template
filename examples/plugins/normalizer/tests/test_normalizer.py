from nomad.client import normalize_all
from nomad.datamodel import EntryArchive, EntryMetadata

def test_normalizer():
    entry_archive = EntryArchive(metadata=EntryMetadata())
    normalize_all(entry_archive)

    assert entry_archive.workflow2.name == 'Example workflow'
