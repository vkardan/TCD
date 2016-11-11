# This class provides necessary methods for creating datasets. 
#
# @author: Vahid Kardan
class Dataset

	def initialize

	end

	def self.create_dataset_from_gml_file(input:, graph_path:, clusters_path:, first_node_id: 1)
		n = 0
		m = 0
		index = first_node_id
		state = 0
		node = Hash.new
		edge = Hash.new
		graph = Hash.new
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
				node['id'] = items[1].to_i
				graph[node['id']] = Hash.new
				graph[node['id']]['id'] = index
				state = 2
			when 'value'
				raise 'Bad value format!' if state != 2
				node['cluster'] = items[1].to_i + 1
				#clusters.puts node['id']+' '+node['cluster']
				graph[node['id']]['cluster'] = node['cluster']
				n += 1
				index += 1
				state = 3
			when 'source'
				raise 'Bad source format!' if state != 10 && state != 3
				if state == 10 then
					edge['source'] = items[1].to_i 
					state = 11
				else # state = 3
					state = 0 
				end
			when 'target'
				raise 'Bad target format!' if state != 11
				edge['target'] = items[1].to_i
				#graph.puts edge['source']+' '+edge['target']
				graph[edge['source']]['children'] ||= []
				graph[edge['source']]['children'] << edge['target'] 
				m += 1
				state = 0
			end						
		end
		puts graph.size
		graph = graph.sort.to_h
		File.open(clusters_path, 'w') do |c|
			graph.each do |s, h|
				raise 'Bad format, no id found for node with source: #{s}' if h['id'].nil?
				raise 'Bad format, no cluster found for node with source: #{s}' if h['cluster'].nil?
				c.puts "#{h['id']} #{h['cluster']}"
			end
		end
		File.open(graph_path, 'w') do |g|
			graph.each do |s, h|
				h['children'].sort.each { |child| g.puts "#{h['id']} #{child}" } unless h['children'].nil?
			end
		end
		File.open(graph_path+'.meta', 'w') {|f| f.puts "N: #{n}, M: #{m}"}
	end
end

path = '/home/vahid/Dropbox/Vahid-Research/community-detection/datasets/polblogs/'
Dataset.create_dataset_from_gml_file(
	input: path+'polblogs.gml', 
	graph_path: path+'polblogs.txt', 
	clusters_path: path+'polblogs.clu',
	first_node_id: 1
)
