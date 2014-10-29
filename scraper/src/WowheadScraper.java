import org.apache.commons.lang.NumberUtils;
import org.apache.commons.lang.StringUtils;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
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
        List<Callable<Pair>> callables = new ArrayList<>();

        List<String> jsonny = splitStrings(dataFile);
        for (int i = 0; i < jsonny.size(); i++) {
            final int iCopy = i;
            String s = jsonny.get(i);
            if (s.length() > 3) {
                String noQuotes = s.substring(1, s.length() - 2);
                if (NumberUtils.isNumber(noQuotes)) {
                    callables.add(() -> scrapeName(iCopy, noQuotes));
                }
            }
        }

        final ExecutorService threadPool = Executors.newFixedThreadPool(10);
        List<Future<Pair>> results = threadPool.invokeAll(callables);
        List<Pair> realResults = new ArrayList<>();
        for (Future<Pair> f : results) {
            realResults.add(f.get());
        }

        realResults.forEach(p -> jsonny.set(p.lhs, "\"" + p.rhs + "\""));
        String json = StringUtils.join(jsonny, "");
        PrintWriter out = new PrintWriter(dataFile);
        out.write(json);
        out.close();
        System.exit(1);
    }

    private Pair scrapeName(int i, String id) {
        final String wowheadUrl = "http://www.wowhead.com/";
        final List<String> wowheadTypes = Arrays.asList("item", "npc", "spell", "quest");

        for (String type : wowheadTypes) {
            String scraped = scrapePage(wowheadUrl + type + "=" + id);
            if (scraped != null) {
                return new Pair(i, id + ":" + scraped);
            }
        }
        return new Pair(i, id + ":");
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

    private List<String> splitStrings(String dataFile) {
        try (BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(dataFile)))) {
            List<String> lines = br.lines().collect(Collectors.toList());
            StringBuilder sb = new StringBuilder();
            for (String s : lines) {
                sb.append(s);
            }
            return Arrays.asList(sb.toString().split("(?=[\\\n\\\t\\[\\]\\\"\\{\\},])(?:)(?<=[\\\n\\\t\\[\\]\\\"\\{\\},])"));
        } catch (Exception e) {
            return null;
        }

    }


    private final class Pair {
        public final int lhs;
        public final String rhs;

        public Pair(int a, String b) {
            lhs = a;
            rhs = b;
        }

        @Override
        public String toString() {
            return String.valueOf(lhs) + " " + rhs;
        }
    }
}
