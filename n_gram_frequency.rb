require 'csv'
require 'awesome_print'
require 'magic_cloud'

class BasicWordFrequenciesDelighted
  attr_accessor :responses, :words, :n_grams

  def initialize(file)
    csv_string = File.read(file)
    keys = [:reponse_id, :name, :email, :score, :comment, :response_time, :notes, :tags]
    @responses = CSV.parse(csv_string).map {|a| Hash[ keys.zip(a) ] }
    @words = {}
    @n_grams = {}
  end

  def populate_word_frequencies!
    comments = responses.flat_map { |response| response[:comment]}.select { |x| !x.empty? }
    stripped = comments.map {|string| string.downcase.gsub(/[^a-z0-9\s]/i, '').split(' ')}.flatten
    stripped.each do |word|
      words[word] = 1 unless words[word]
      if words[word]
        words[word] += 1
      end
    end
    words
  end

  def n_gram(n)
    responses.map do |response|
      next if response[:comment].empty?
      stripped = response[:comment].downcase.gsub(/[^a-z0-9\s]/i, '').split(' ')
      stripped.each_cons(n) do |slice|
        n_grams[slice] = 1 unless n_grams[slice]
        if n_grams[slice]
          n_grams[slice] += 1
        end
      end
    end
    n_grams
  end

  def words_occuring_10_plus_times(hash, gram)
    populate_word_frequencies!
    popular = hash.select {|_, v| v >= 10}
    date = Date.today.strftime('%m-%d-%Y')
    CSV.open("word_frequency_#{date}_#{gram}_gram.csv", "wb") do |csv|
      csv << ['Word', "Frequency"]
      popular.each do |k, v|
        csv << [k.join(' '), v]
      end
    end
  end

  def cloud
    MagicCloud::Cloud.new(words, rotate: :free, scale: :log)
  end

  def txt
    comments = responses.flat_map { |response| response[:comment]}.select { |x| !x.empty? }
    stripped = comments.map {|string| string.downcase.gsub(/[^a-z0-9\s]/i, '')}.flatten
    open('words.txt', 'w') { |file| file.write(stripped.join(' ')) }
  end
end

survey = BasicWordFrequenciesDelighted.new('scripts/delighted-data_10-August-2018.csv')
puts survey.n_gram(4)
n_grams =  survey.words_occuring_10_plus_times(survey.n_grams, 4)


