class PicoDilutionPlate < DilutionPlate
  self.prefix = "PD"
  
  def self.index_to_hash(pico_dilutions)
    pico_dilutions.map{ |pico_dilution| pico_dilution.to_hash }
  end

  def study_name
    return "" if studies.blank?
    studies.first.name
  end
  
  def to_hash
    {:pico_dilution => {
        :child_barcodes => children.map{ |plate| plate.barcode_and_created_at_hash }
      }.merge(barcode_and_created_at_hash),
        :study_name => study_name
    }
  end

end
