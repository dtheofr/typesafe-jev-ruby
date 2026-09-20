# frozen_string_literal: true

module Typesafe
  # A System One evaluation response: the model that performed the
  # evaluation, one typed {Answer} per question (keyed by the question ids
  # from the request), and the token {Usage}.
  #
  #   response = Typesafe::Response.from_json(json)
  #   response[:refund_requested] # => #<Typesafe::NoulAnswer @noul=0.95>
  #
  # The answer objects do not carry their question id — it is the Hash key
  # under which each answer appears in {#answers}, mirroring how questions
  # are sent.
  class Response
    # @return [String] the model that performed the evaluation.
    attr_reader :model

    # @return [Hash] question ids (String or Symbol) mapped to Answer objects.
    attr_reader :answers

    # @return [Usage] the token usage for the request.
    attr_reader :usage

    # @param model [String] the model that performed the evaluation.
    # @param answers [Hash] question ids (String or Symbol) mapped to Answer
    #   objects or answer Hashes; Hashes are parsed via {Answer.from_h}.
    # @param usage [Usage, Hash] a Usage object, or a +usage+ Hash parsed
    #   via {Usage.from_h}.
    # @raise [ArgumentError] if any attribute is invalid or an answer is not
    #   parseable.
    def initialize(model:, answers:, usage:)
      @model = freeze_string(model, "model must be a non-empty String")
      @answers = normalize_answers(answers)
      @usage = usage.is_a?(Usage) ? usage : Usage.from_h(usage)
      freeze
    end

    # Parses a raw JSON response body from the TypeSafe API.
    #
    # @param json [String] the response body.
    # @return [Response]
    # @raise [ArgumentError] if the body is not a valid response shape.
    # @raise [JSON::ParserError] if +json+ is not valid JSON.
    def self.from_json(json)
      from_h(JSON.parse(json))
    end

    # @param hash [Hash] the parsed response body, with String or Symbol keys.
    # @return [Response]
    # @raise [ArgumentError] if +hash+ is not a valid response shape.
    def self.from_h(hash)
      unless hash.is_a?(Hash)
        raise ArgumentError, "response must be a Hash, got #{hash.inspect}"
      end

      new(
        model: hash["model"] || hash[:model],
        answers: hash["answers"] || hash[:answers],
        usage: hash["usage"] || hash[:usage]
      )
    end

    # The answer for a question id.
    #
    # @param id [String, Symbol] the question id used in the request.
    # @return [Answer, nil] the matching answer, or nil if the id is unknown.
    def [](id)
      answers[id] || (id.is_a?(Symbol) ? answers[id.to_s] : nil)
    end

    # @return [Hash] the response shape returned by the TypeSafe API.
    def to_h
      { model: model, answers: answers.transform_values(&:to_h), usage: usage.to_h }
    end

    # @return [String] the response serialized as JSON.
    def to_json(state = nil)
      JSON.generate(to_h, state)
    end

    # Responses compare equal when they are of the same class and serialize
    # to the same API shape.
    def ==(other)
      other.class == self.class && other.to_h == to_h
    end
    alias eql? ==

    def hash
      [self.class, to_h].hash
    end

    private

    # Validates that +model+ is a non-empty String and returns a frozen copy.
    def freeze_string(value, error_message)
      unless value.is_a?(String) && !value.strip.empty?
        raise ArgumentError, error_message
      end

      value.dup.freeze
    end

    # Validates that +answers+ is a non-empty Hash of question ids to
    # (or parseable) Answer objects, and freezes its keys.
    def normalize_answers(answers)
      unless answers.is_a?(Hash) && !answers.empty?
        raise ArgumentError, "answers must be a non-empty Hash mapping question ids to answers"
      end

      answers.each_with_object({}) do |(id, answer), normalized|
        unless (id.is_a?(String) && !id.strip.empty?) || (id.is_a?(Symbol) && !id.to_s.strip.empty?)
          raise ArgumentError, "answers keys must be non-empty String or Symbol question ids, got #{id.inspect}"
        end

        normalized[id.is_a?(String) ? id.dup.freeze : id] =
          if answer.is_a?(Answer)
            answer
          elsif answer.is_a?(Hash)
            Answer.from_h(answer)
          else
            raise ArgumentError,
                  "answers[#{id.inspect}] must be an answer Hash or Answer object, got #{answer.inspect}"
          end
      end.freeze
    end
  end
end
