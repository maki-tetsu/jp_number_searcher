require 'nokogiri'
require 'httpclient'

module JpNumberSearcher
  BASE_URL = 'https://trackings.post.japanpost.jp/services/srv/search/'
  QUERY_PREFIX = 'requestNo'
  DEFAULT_PARAMS = { :search => '検索スタート' }
  DUMMY_NUMBER = '0000-0000-0000'
  RESULT_TABLE_XPATH = '//table[@summary="照会結果"]'

  TD_INDEX_FOR_SLIP_NUMBER     = 1
  TD_INDEX_FOR_ERROR_LABEL     = 2
  TD_INDEX_FOR_LAST_UPDATED_AT = 3
  TD_INDEX_FOR_STATUS_LABEL    = 4

  SLIP_NUMBERS_PER_PAGE = 10

  def self.search(numbers)
    numbers.each_slice(SLIP_NUMBERS_PER_PAGE).inject([]) do |result, slice|
      content = get_content(BASE_URL, build_params(slice))
      slice_result = parse_content(content)
      yield(slice_result) if block_given?

      result += slice_result
    end
  end

  def self.build_params(numbers)
    query_prefix = 'requestNo'

    hash = SLIP_NUMBERS_PER_PAGE.times.each_with_object({}) do |index, hash|
      if numbers[index].nil?
        hash["#{query_prefix}#{index+1}"] = DUMMY_NUMBER
      else
        hash["#{query_prefix}#{index+1}"] = numbers[index]
      end
    end

    hash.merge(DEFAULT_PARAMS)
  end

  def self.get_content(base_url, params)
    client = HTTPClient.new
    client.get_content(base_url, params) # TODO 通信エラーの対応が必要
  end

  def self.parse_content(content)
    doc = Nokogiri::HTML.parse(content)
    table = doc.at_xpath(RESULT_TABLE_XPATH)

    raise 'Result table not found!!' unless table

    result = table.xpath('tr').map do |tr|
      next if tr.xpath('td').count <= 1 # skip because post office zip code
      parse_tr(tr)
    end

    result.compact
  end

  def self.parse_tr(tr)
    slip_number = parse_slip_number(tr)

    if dummy_record?(slip_number)
      nil
    elsif tr.xpath('td').count == 2
      {
        :slip_number => slip_number,
        :error_label => parse_error_label(tr)
      }
    else
      {
        :slip_number => slip_number,
        :last_updated_at => parse_last_updated_at(tr),
        :status_label => parse_status_label(tr)
      }
    end
  rescue => e
    {
      :slip_number => slip_number,
      :error_label => e.to_s
    }
  end

  def self.parse_slip_number(tr_element)
    td_element = tr_element.at_xpath("td[#{TD_INDEX_FOR_SLIP_NUMBER}]")
    if (text_element = td_element.at_xpath('a/text()'))
      text_element.content
    else
      td_element.content
    end
  end

  def self.parse_last_updated_at(tr_element)
    td_element = tr_element.at_xpath("td[#{TD_INDEX_FOR_LAST_UPDATED_AT}]")
    td_element.
      content.
      strip.
      gsub(/[\r\n]/, '').
      gsub(/\ {2,}/, ' ')
  end

  def self.parse_status_label(tr_element)
    td_element = tr_element.at_xpath("td[#{TD_INDEX_FOR_STATUS_LABEL}]")
    td_element.content
  end

  def self.parse_error_label(tr_element)
    td_element = tr_element.at_xpath("td[#{TD_INDEX_FOR_ERROR_LABEL}]")
    td_element.content
  end

  def self.dummy_record?(slip_number)
    slip_number.gsub('-', '') == DUMMY_NUMBER.gsub('-', '') # DUMMY NUMBER
  end
end
