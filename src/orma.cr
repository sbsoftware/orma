require "./orma/record"

if ENV.fetch("ORMA_CONTINUOUS_MIGRATION", "").in?(["1", "true"])
  {% for orm_class in Orma::Record.all_subclasses %}
    {% if !orm_class.abstract? %}
      puts "Creating table for #{{{orm_class.id}}}"
      {{orm_class.id}}.ensure_table_exists!
    {% end %}
  {% end %}
end
