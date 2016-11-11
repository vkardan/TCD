# WARNING, This class is deprecated right now, use KvmClassifierModel model instead.
# This class represents KVM classifier based on CSV files.
# It provide the required methods for calling the Primal APIs.
#
# @author: Vahid Kardan
class Dataset

	def initialize

	end

	# mode: :labeled, :unlabeled, :all
	def self.create_dataset(input:, output:, type: )
		case type
		when 'gml'
			create_dataset_from_gml_file(input: input, output: output)
		end
	end

private
	def create_dataset_from_gml_file(input:, output:)
		n = 0
		m = 0
		state = 0
		node = Hash.new
		edge = Hash.new
		File.open(output, 'w') do |fo|	
			fo.puts "Label,Condition,URL,Title,Tags,Sentiment Label,Sentiment Score,Sentiment Mixed" if header
			fi = File.open(input, "r")
			fi.each_line do |line| 
				items = line.split(/\s/) - [""]
				case items[0]
				when 'node'
					state = 1
				when 'edge'
					state = 10
				when 'id'
					raise 'Bad id format!' if state != 1
					node['id'] = items[1]
					state = 2
				when 'value'
					raise 'Bad value format!' if state != 2
					node['cluster'] = items[1]
					fo.puts node['id']+' '+node['value']
					state = 3
				when 'source'
					raise 'Bad source format!' if state != 10 || state != 3
					if state = 10 then
						edge['source'] = items[1] 
						state = 11
					else # state = 3
						state = 0 
					end
				when 'target'
					raise 'Bad target format!' if state != 11
					edge['target'] = items[1]
					fo.puts edge['source']+' '+edge['target']
					state = 0
				end						
			end
		end
	end
end
