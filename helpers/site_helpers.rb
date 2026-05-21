# frozen_string_literal: true

module SiteHelpers
  def localhost?
    `hostname`.strip =~ /mbair/ ? true : false
  end

  def thisyear
    data.year.thisyear
  end
end
