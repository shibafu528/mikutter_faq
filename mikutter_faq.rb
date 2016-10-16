# -*- coding: utf-8 -*-
require 'json'
require 'open-uri'
require 'nokogiri'

module Plugin::Faq
  class Question < Retriever::Model
    include Retriever::Model::UserMixin

    field.string :name, required: true

    def profile_image_url
      Skin.get('icon.png')
    end

    def idname; nil; end
  end
  
  class Faq < Retriever::Model
    include Retriever::Model::MessageMixin

    register :faq, name: "FAQ"

    field.string :question, required: true
    field.string :answer, required: true
    field.time   :created
    field.has    :user, Plugin::Faq::Question

    def to_show
      @to_show ||= self[:question] + "\n\n" + self[:answer]
    end

    def user
      self[:user] ||= Plugin::Faq::Question.new(name: 'mikutter FAQ')
    end

    def uri
      self[:uri] ||= URI('faq://faq/' + self[:question].hash.to_s)
    end
  end

end

Plugin.create(:mikutter_faq) do

  filter_extract_datasources do |ds|
    [ds.merge(faq: 'mikutter FAQ')]
  end

  def tick
    Thread.new {
      open('http://mikutter.hachune.net/faq.json').read
    }.next { |doc|
      JSON.parse(doc)
    }.next { |json|
      json.map do |item|
        Plugin::Faq::Faq.new(question: item[0], 
                             answer:   Nokogiri::HTML(item[1]).content, 
                             created:  Time.now)
      end
    }.next { |items|
      Plugin.call :extract_receive_message, :faq, items
    }

    Reserver.new(3600) { tick }
  end

  tick
end
