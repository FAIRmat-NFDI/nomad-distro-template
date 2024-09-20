from nomad.metainfo import Quantity, Package
from nomad.datamodel.data import EntryData
from nomad.datamodel.metainfo.annotations import ELNAnnotation, ELNComponentEnum

m_package = Package()


class ExampleSection(EntryData):
    name = Quantity(
        type=str,
        a_eln=ELNAnnotation(component=ELNComponentEnum.StringEditQuantity))
    message = Quantity(type=str)

    def normalize(self, archive, logger):
        super(ExampleSection, self).normalize(archive, logger)
        logger.info('ExampleSection.normalize called')

        self.message = f'Hello {self.name}!'


m_package.__init_metainfo__()
