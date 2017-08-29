require "./deeplcr/*"
require "http/client"
require "json"

module Deeplcr
  ENDPOINT = "https://www.deepl.com/jsonrpc"

  LANGUAGES = {"auto", "DE", "EN", "FR", "ES", "IT", "NL", "PL"}

  def self.translate(text : String, lang_from : String, lang_to : String) : String
    body = {
      "jsonrpc" => "2.0",
      "method"  => "LMT_handle_jobs",
      "params"  => {
        "jobs" => [
          {
            "kind"            => "default",
            "raw_en_sentence" => text,
          },
        ],
        "lang" => {
          "user_preferred_langs" => [
            lang_from,
            lang_to,
          ],
          "source_lang_user_selected" => lang_from,
          "target_lang"               => lang_to,
        },
        "priority" => -1,
      },
      "id" => 42,
    }.to_json
    HTTP::Client.post(url: ENDPOINT, body: body) do |response|
      result = ""
      begin
        result = response.body_io.gets_to_end.to_s
        parsed = JSON.parse(result)
        t1 = parsed["result"]["translations"][0]["beams"][0]["postprocessed_sentence"].as_s
        return t1
      rescue err
        pp JSON.parse(result)
        raise err
      end
    end
    raise "Failed to get the translation"
    ""
  end
end

require "option_parser"

lang_from = "FR"
lang_to = "EN"
text = ""
mode = :args
verbose = 1

OptionParser.parse! do |parser|
  parser.banner = "Usage: deeplcr [arguments]"
  parser.on("-f LANG", "--lang_from=LANG", "Set the lang of the input text") do |v|
    lang_from = v
  end
  parser.on("-t LANG", "--lang_to=LANG", "Set the lang of the output text") do |v|
    lang_to = v
  end
  parser.on("-s", "--stdin", "Read stdin as input text") do |v|
    mode = :stdin
  end
  parser.on("-a", "--arguments", "Use arguments as input text") do |v|
    mode = :args
  end
  parser.on("-a", "--arguments", "Use arguments as input text") do |v|
    mode = :args
  end
  parser.on("-o", "--only-translation", "Minimal output") do |v|
    verbose = 0
  end
  parser.on("-h", "--help", "Show this help") { puts parser; exit }
end

mode = :stdin if ARGV.empty?

case mode
when :stdin
  text = STDIN.gets_to_end.to_s
when :args
  text = ARGV.map(&.strip).join(" ")
else
  raise "Error: invalid mode"
end

if verbose > 0
  puts "FROM: #{lang_from}"
  puts "TO  : #{lang_to}"
  puts "TEXT: #{text}"
  puts "------" + "-" * text.size
else
  puts Deeplcr.translate(text, lang_from, lang_to)
end
