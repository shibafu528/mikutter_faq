# -*- coding: utf-8 -*-
require 'json'
require 'open-uri'

module Plugin::Faq
  class Question < Retriever::Model
    include Retriever::Model::UserMixin

    field.string :name, required: true

    def profile_image_url
      Skin['icon.png']
    end
  end
  
  class Faq < Retriever::Model
    include Retriever::Model::MessageMixin

    register :faq, name: "FAQ"

    field.string :question, required: true
    field.string :answer, required: true
    field.string :id, required: true
    field.time   :created
    field.has    :user, Plugin::Faq::Question

    def path
      "/#{id}"
    end

    def description
      "#{question}\n\n#{answer}"
    end
  end

end

Plugin.create(:mikutter_faq) do

  filter_extract_datasources do |ds|
    [ds.merge(faq: 'mikutter FAQ')]
  end

  def tick
    Thread.new {
      URI.open('https://mikutter.hachune.net/faq.json').read
    }.next { |doc|
      JSON.parse(doc, symbolize_names: true)
    }.next { |json|
      json.map do |item|
        Plugin::Faq::Faq.new(created:  Time.now,
                             user: {name: 'mikutter FAQ'},
                             **item)
      end
    }.next { |items|
      Plugin.call :extract_receive_message, :faq, items
    }.terminate

    Reserver.new(3600) { tick }
  end

  tick
end
