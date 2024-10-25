require "opentelemetry-sdk"

class DB::Statement
  def_around_query_or_exec do |args|
    OpenTelemetry.tracer.in_span(command) do |span|
      span.client!
      span["db.statement"] = command

      yield
    end
  end
end
