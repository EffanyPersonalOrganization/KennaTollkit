# frozen_string_literal: true

require_relative "lib/sysdig_client"
require_relative "lib/runtime_mapper"
require_relative "lib/static_mapper"

module Kenna
  module Toolkit
    module Sysdig
      class Task < Kenna::Toolkit::BaseTask
        def self.metadata
          {
            id: "sysdig",
            name: "Sysdig",
            description: "Pulls assets and vulnerabilities from Sysdig",
            options: [
              { name: "sysdig_api_host",
                type: "hostname",
                required: true,
                default: nil,
                description: "Sysdig hostname depending on SaaS region, e.g. us2.app.sysdig.com" },
              { name: "sysdig_api_token",
                type: "api_key",
                required: true,
                default: nil,
                description: "Sysdig User API token" },
              { name: "sysdig_severity_mapping",
                type: "string",
                required: false,
                default: "Critical:8,High:7,Medium:5,Low:3,Negligible:0,Unknown:0",
                description: "Maps Severity name to 0-10 Kenna severity score. The score has effect on non CVE vulnerabilities, e.g. VULNDB" },
              { name: "sysdig_vuln_severity",
                type: "string",
                required: false,
                default: nil,
                description: "A comma separated list of severity types to import. Allowed are Critical, High, Medium, Low, Negligible, Unknown. Import all if absent." },
              { name: "sysdig_page_size",
                type: "integer",
                required: false,
                default: 500,
                description: "Maximum number of issues to retrieve in each page." },
              { name: "import_type",
                type: "string",
                required: false,
                default: "ALL",
                description: "Choose what to import: STATIC, RUNTIME or ALL." },
              { name: "kenna_batch_size",
                type: "integer",
                required: false,
                default: 500,
                description: "Maximum number of issues to upload to kenna in batches." },
              { name: "kenna_api_key",
                type: "api_key",
                required: false,
                default: nil,
                description: "Kenna API Key" },
              { name: "kenna_api_host",
                type: "hostname",
                required: false,
                default: "api.kennasecurity.com",
                description: "Kenna API Hostname" },
              { name: "kenna_connector_id",
                type: "integer",
                required: false,
                default: nil,
                description: "If set, we'll try to upload to this connector" },
              { name: "output_directory",
                type: "filename",
                required: false,
                default: "output/sysdig",
                description: "If set, will write a file upon completion. Path is relative to #{$basedir}" }
            ]
          }
        end

        def run(opts)
          super
          initialize_options
          initialize_client

          import_static if %w[static all].include?(@import_type)
          import_runtime if %w[runtime all].include?(@import_type)

          kdi_connector_kickoff(@kenna_connector_id, @kenna_api_host, @kenna_api_key)
        rescue Kenna::Toolkit::Sysdig::Client::ApiError => e
          fail_task e.message
        end

        private

        def initialize_options
          @host = @options[:sysdig_api_host]
          @api_token = @options[:sysdig_api_token]
          @severity_mapping = build_severity_mappings(@options[:sysdig_severity_mapping])
          @vuln_severity = extract_list(:sysdig_vuln_severity)
          @page_size = @options[:sysdig_page_size].to_i
          @import_type = @options[:import_type].downcase
          @output_directory = @options[:output_directory]
          @batch_size = @options[:kenna_batch_size].to_i
          @kenna_api_host = @options[:kenna_api_host]
          @kenna_api_key = @options[:kenna_api_key]
          @kenna_connector_id = @options[:kenna_connector_id]
          @skip_autoclose = false
          @retries = 3
          @kdi_version = 2
          @vuln_definitions = {}
        end

        def extract_list(key, default = nil)
          list = (@options[key] || "").split(",").map(&:strip)
          list.empty? ? default : list
        end

        def build_severity_mappings(mappings)
          mappings.split(",").to_h { |key_value| key_value.split(":") }.transform_values!(&:to_i)
        end

        def initialize_client
          @client = Kenna::Toolkit::Sysdig::Client.new(@host, @api_token, @page_size, @vuln_severity)
        end

        def import_static
          import_vulnerabilities(@client.static_vulnerabilities, StaticMapper)
        end

        def import_runtime
          import_vulnerabilities(@client.runtime_vulnerabilities, RuntimeMapper)
        end

        def import_vulnerabilities(paged_vulns, mapper_class)
          total_vulns = 0

          kdi_batch_upload(@batch_size, @output_directory, "sysdig_#{mapper_class.import_type.downcase}.json", @kenna_connector_id, @kenna_api_host, @kenna_api_key, @skip_autoclose, @retries, @kdi_version) do |batch|
            paged_vulns.each do |vulns|
              add_vuln_definitions(vulns)
              vulns.each do |vuln|
                batch.append do
                  mapper = mapper_class.new(vuln, @severity_mapping, @vuln_definitions)
                  create_kdi_asset_vuln(mapper.extract_asset, mapper.extract_vuln)
                  create_kdi_vuln_def(mapper.extract_definition)
                end
              end

              print_good "Processed #{vulns.count} #{mapper_class.import_type} vulnerabilities."
              total_vulns += vulns.count
            end
          end

          print_good "A total of #{total_vulns} #{mapper_class.import_type} vulnerabilities processed."
        end

        # Kenna only knows vuln ids from CVE, CWE o WASC so wee need to get unknown definitions from Sysdig.
        def add_vuln_definitions(vulns)
          non_standard_vuln_ids = vulns.map { |v| v["vuln"] }.grep_v(/CVE-.*|CWE-.*|WASC-.*/).uniq
          @client.vuln_definitions(non_standard_vuln_ids).each do |vuln_def|
            @vuln_definitions[vuln_def["name"]] = vuln_def
          end
        end
      end
    end
  end
end
