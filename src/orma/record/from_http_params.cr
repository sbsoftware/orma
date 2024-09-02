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
            when {{ivar.name.stringify}}
              %var{ivar.name} = {{ivar.type.type_vars.first.union_types.select { |t| t != Nil }.first}}.from_http_param(value)
            {% end %}
            end
          {% end %}
        end

        {% for ivar in @type.instance_vars %}
          if %var{ivar.name}
            self.{{ivar.name.id}} = %var{ivar.name}
          else
            {% if !ivar.type.type_vars.first.union_types.includes?(Nil) %}
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
          when {{ivar.name.stringify}}
            %parsed_value = {{ivar.type.type_vars.first.union_types.select { |t| t != Nil }.first }}.from_http_param(value)
            if %parsed_value
              self.{{ivar.name.id}} = %parsed_value
            else
              {% if ivar.type.type_vars.first.union_types.includes?(Nil) %}
                self.{{ivar.name.id}} = nil
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
