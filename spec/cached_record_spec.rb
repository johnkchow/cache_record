require 'spec_helper'

describe CachedRecord do
  it 'has a version number' do
    expect(CachedRecord::VERSION).not_to be nil
  end
end
