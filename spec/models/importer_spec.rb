require 'rails_helper'

describe Importer do
  it 'has the grib tools available' do
    expect(system('grib_ls')).to be(true)
  end
end
