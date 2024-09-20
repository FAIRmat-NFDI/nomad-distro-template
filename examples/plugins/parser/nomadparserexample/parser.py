import numpy as np
from nomad.datamodel import EntryMetadata
from nomad.metainfo import MSection, Quantity


class ExampleSection(MSection):
    pattern = Quantity(type=np.float64, shape=['*', '3'])


class ExampleParser:
    def parse(self, mainfile, archive, logger):
        logger.info('parsing started.')

        with open(mainfile, 'rt') as f:
            data = f.readlines()

        archive.metadata = EntryMetadata(external_id=data[0][1:])
        archive.data = ExampleSection()
        archive.data.pattern = [
            [float(number) for number in line.split(' ')]
            for line in data[1:]
        ]
