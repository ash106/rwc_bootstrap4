class PointOfDiversion < ApplicationRecord
  has_many :point_of_diversion_water_rights
  has_many :water_rights, through: :point_of_diversion_water_rights
  validates :name, presence: true, uniqueness: true
  has_attached_file :kml, use_timestamp: false
  # validates_attachment_content_type :kml, content_type: "application/vnd.google-earth.kml+xml"
  validates_attachment_presence :kml
  validates_attachment_file_name :kml, matches: /kml\Z/
  after_save :queue_processing

  def self.for_user(user)
    joins(:water_rights).where(water_rights: { user_id: user.id }).group('point_of_diversions.id')
  end

private
  
  def queue_processing
    if saved_change_to_kml_updated_at?
      parser = KmlParser.new(id, 'PointOfDiversion')
      parser.delay.parse_point
    end
  end
end
