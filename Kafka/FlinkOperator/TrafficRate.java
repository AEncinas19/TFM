package upm.dit.giros;

import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer;
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.functions.windowing.ProcessAllWindowFunction;
import org.apache.flink.streaming.api.windowing.windows.GlobalWindow;
import org.apache.flink.streaming.api.functions.sink.SinkFunction;
import org.apache.flink.streaming.api.functions.source.SourceFunction;
import org.apache.flink.util.Collector;

import java.sql.Timestamp;
import java.util.Collection;
import java.util.Iterator;
import java.util.Properties;
import java.net.URI;
import java.net.URL;
import java.io.BufferedOutputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

public class TrafficRate {

	public static void main(String[] args) throws Exception {
		Properties props = new Properties();
		props.put("bootstrap.servers", args[0]);
		props.put("group.id", "traffic-rate-group");
		props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
		props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
		
		// set up the streaming execution environment
		final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

		// Consume data stream from the Kafka input topic
        FlinkKafkaConsumer<String> consumer = new FlinkKafkaConsumer<String>(args[1], new SimpleStringSchema(), props);
		consumer.setStartFromLatest();

		//Produce data stream on the Kafka output topic
		FlinkKafkaProducer<String> producer = new FlinkKafkaProducer<String>(args[2], new SimpleStringSchema(), props);

        String duration = String.valueOf(Integer.parseInt(args[3]));
		String intf = String.valueOf(args[4]);

		DataStreamSource<String> dss  = env.addSource((SourceFunction<String>) consumer);

		DataStream<String> metric_values = dss.map(new MapFunction<String, String>(){
		    @Override
		    public String map(String value) throws Exception {
				try {
					System.out.println("\nPrometheus metric raw value: " + value);
					JSONArray json_obj = new JSONArray(value);
					JSONObject values = new JSONObject(json_obj.getJSONObject(0).get("values").toString());
					value = values.get("/interfaces/interface/state/counters/in-octets").toString();
					
				} catch (JSONException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				return value;
		    }
		});

		metric_values.countWindowAll(2,1).process(new EventsAggregation(duration, intf)).addSink((SinkFunction<String>)producer);
		
		// execute program
		env.execute("Traffic Rate");
	}

	private static String aggregationMetrics(String value1, String value2, String duration, String intf){
		Double traffic_rate = (Double.parseDouble(value2) - Double.parseDouble(value1)) / Double.parseDouble(duration);
		String value = new String();
		try {
			value = "traffic_rate{interface\"=" + intf + "\"}" + " " + String.valueOf(traffic_rate);
			String urlString = "http://pushgateway:9091/metrics/job/pushgw/interface/" + intf;
			URL url = new URL(urlString);
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("POST");
			// Indicamos que la solicitud HTTP será una solicitud de escritura para enviar datos en una solicitud POST
			conn.setDoOutput(true);

			String requestBody = "# HELP traffic_rate Octetos por segundo en " + intf + "\n" + "# TYPE traffic_rate gauge\n" + "traffic_rate" + "{instance=\"pushgateway\", interface=\"" + intf + "\"}" + " " + traffic_rate + "\n"; 
			//Enviar el cuerpo de la solicitud
			try (OutputStream outputStream = new BufferedOutputStream(conn.getOutputStream())){
				outputStream.write(requestBody.getBytes());
			}

			int responseCode = conn.getResponseCode();
			String responseMessage = conn.getResponseMessage();
			System.out.println(String.valueOf(responseCode) + " " + responseMessage);

			conn.disconnect();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return value;
	}

	public static class EventsAggregation extends ProcessAllWindowFunction<String, String, GlobalWindow>{

                private String duration;
				private String intf;

		EventsAggregation(String duration, String intf){
			this.duration = duration;
			this.intf = intf;
		}

		private int size(Iterable data) {
	
			if (data instanceof Collection) {
				return ((Collection<?>) data).size();
			}
			int counter = 0;
			for (Object i : data) {
				counter++;
			}
			return counter;
		}
		
		@Override
		public void process(Context context, Iterable<String> elements, Collector<String> out) throws Exception {
			int windowSize = size(elements);
			if(windowSize == 2){
				Iterator<String> it = elements.iterator();
				String new_metric = aggregationMetrics(it.next(), it.next(), duration, intf);
				out.collect(new_metric);
			}
		}
	} 
}