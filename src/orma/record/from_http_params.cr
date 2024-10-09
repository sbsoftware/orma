require "../record"

module Orma
  abstract class Record
    def self.from_http_params(str : String)
      new(__http_params: str)
    end

    def self.new(*, __http_params : String)
      instance = allocate
      instance.initialize(__http_params: __http_params)
      GC.add_finalizer(instance) if instance.responds_to? :finalize
      instance
    end

    def initialize(*, __http_params : String)
      {% begin %}
        {% for ivar in @type.instance_vars %}
          %var{ivar.name} = nil
        {% end %}

        HTTP::Params.parse(__http_params) do |key, value|
          {% begin %}
            case key
            {% for ivar in @type.instance_vars %}
            {% setter = ((ann = ivar.annotation(Orma::Column)) ? ann[:setter] : nil) || ivar.name.id %}
            when {{setter.stringify}}
              %var{ivar.name} = {{ivar.type.union_types.find { |t| t != Nil }.type_vars.first}}.from_http_param(value)
            {% end %}
            end
          {% end %}
        end

        {% for ivar in @type.instance_vars %}
          unless %var{ivar.name}.nil?
            {% if (ann = ivar.annotation(Orma::Column)) && (transform_in = ann[:transform_in]) %}
              %var{ivar.name} = {{transform_in}}(%var{ivar.name})
            {% end %}
            @{{ivar.name}} = ::Orma::Attribute.new(self.class, {{ivar.name.symbolize}}, %var{ivar.name})
          else
            {% unless ivar.type.nilable? || ivar.has_default_value? %}
              raise ArgumentError.new("Missing attribute: {{ivar.name.id}}")
            {% end %}
          end
        {% end %}
      {% end %}
    end

    def assign_http_params(params)
      {% begin %}
        HTTP::Params.parse(params) do |key, value|
          case key
          {% for ivar in @type.instance_vars %}
          {% setter = ((ann = ivar.annotation(Orma::Column)) ? ann[:setter] : nil) || ivar.name.id %}
          when {{setter.stringify}}
            %parsed_value = {{ivar.type.union_types.find { |t| t != Nil }.type_vars.first }}.from_http_param(value)
            if %parsed_value
              self.{{setter}} = %parsed_value
            else
              {% if ivar.type.nilable? %}
                self.{{setter}} = nil
              {% else %}
                raise ArgumentError.new("Invalid value #{value.dump} for {{ivar.name.id}}")
              {% end %}
            end
          {% end %}
          end
        end
      {% end %}
    end
  end
end
