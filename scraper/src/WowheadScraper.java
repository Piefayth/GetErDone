import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

public class WowheadScraper {
    public static void main(String[] args) throws Exception {
        WowheadScraper s = new WowheadScraper();
        s.scrape(args[0]);
    }

    private static final int ATTEMPTS = 6;
    private static final Map<String, Document> pageCache = new ConcurrentHashMap<>();
    private static AtomicInteger cacheRetrivals = new AtomicInteger(0);


    public WowheadScraper() {

    }

    public void scrape(String dataFile) throws Exception {
        JSONObject db = getDb(dataFile);
        List<Callable<Pair>> callables = new ArrayList<>();

        for (Object charName : db.values()) {
            for (Object itemType : (JSONArray) charName) {
                for (Object wowIdObj : ((JSONObject) itemType).values()) {
                    String wowId = (String) wowIdObj;
                    callables.add(() -> scrapeName(wowId));
                }
            }
        }

        final ExecutorService threadPool = Executors.newFixedThreadPool(10);
        List<Future<Pair>> results = threadPool.invokeAll(callables);
        List<Pair> realResults = new ArrayList<>();
        for (Future<Pair> f : results) {
            realResults.add(f.get());
        }

        realResults.forEach(System.out::println);
    }

    private Pair scrapeName(String id) {
        final String wowheadUrl = "http://www.wowhead.com/";
        final List<String> wowheadTypes = Arrays.asList("item", "npc", "spell", "quest");

        for (String type : wowheadTypes) {
            String scraped = scrapePage(wowheadUrl + type + "=" + id);
            if (scraped != null) {
                return new Pair(id, scraped);
            }
        }
        return new Pair(id, "");
    }

    private String scrapePage(String url) {
        Document page = getPage(url);
        if (page == null) {
            return null;
        }
        if (page.head().getElementsByTag("title").get(0).html().contains("Error")) {
            return null;
        }
        return page.body().getElementsByClass("heading-size-1").get(0).text();
    }

    private Document getPage(String url) {
        System.out.println("Getting page: " + url);
        if (pageCache.containsKey(url)) {
            cacheRetrivals.incrementAndGet();
            return pageCache.get(url);
        } else {
            try {
                Connection c = Jsoup.connect(url);
                c.timeout(10000);

                for (int i = 0; i < ATTEMPTS; i++) {
                    try {
                        Document d = c.get();
                        if (d != null) {
                            System.out.println("SUCCESS " + url);
                            synchronized (pageCache) {
                                pageCache.put(url, d);
                            }
                            return d;
                        }
                    } catch (Exception e) {
                        System.out.println(" ... attempt " + (i + 2));
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        }

    }

    private JSONObject getDb(String dataFile) {
        try (BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(dataFile)))) {
            List<String> lines = br.lines().collect(Collectors.toList());
            StringBuilder sb = new StringBuilder();
            for (String s : lines) {
                sb.append(s);
            }
            return (JSONObject) JSONValue.parse(sb.toString().replace("\t", "").replace("\n", ""));
        } catch (Exception e) {
            return null;
        }
    }


    private final class Pair {
        public final String lhs;
        public final String rhs;

        public Pair(String a, String b) {
            lhs = a;
            rhs = b;
        }

        @Override
        public String toString() {
            return lhs + " " + rhs;
        }
    }
}
