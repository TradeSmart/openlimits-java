package io.nash.openlimits;

import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.Callable;
import java.util.function.Consumer;

/**
 * We are wrapping Nash calls to recreate the client after a "Could not register request with broker" error
 * This is neccessary because the library is actually using websockets to make the requests and requires recreating the client if connection is broken
 * When Nash adds an auto-reconnect on the Rust web sockets we should be able to remove this wrapper
 */
public class NashClient {
    NashCredentials credentials;
    ExchangeClient client;
    Map<String, Consumer<TradesResponse>> tradeSubscriptions = new HashMap<String, Consumer<TradesResponse>>();

    private void buildClient() {
        client = new ExchangeClient(
                new ExchangeClientConfig(
                        new NashConfig(
                                credentials,
                                0,
                                "production",
                                10000,
                                "2PTzyS"
                        )
                )
        );

        for (Map.Entry<String,  Consumer<TradesResponse>> entry : tradeSubscriptions.entrySet()) {
            subscribeTrades(entry.getKey(), entry.getValue());
        }
    }

    public NashClient() {
        buildClient();
    }

    public NashClient(String apiKey, String secretKey) {
        credentials = new NashCredentials(secretKey, apiKey);
        buildClient();
    }

    public Order limitBuy(LimitRequest request) {
        return wrapCall((Callable<Order>) () -> client.limitBuy(request));
    }

    public Order limitSell(LimitRequest request) {
        return wrapCall((Callable<Order>) () -> client.limitSell(request));
    }

    public Order marketSell(MarketRequest request) {
        return wrapCall((Callable<Order>) () -> client.marketSell(request));
    }

    public Balance[] getAccountBalances(Paginator paginator) {
        return wrapCall((Callable<Balance[]>) () -> client.getAccountBalances(paginator));
    }
    public OrderCanceled cancelOrder(CancelOrderRequest req) {
        return wrapCall((Callable<OrderCanceled>) () -> client.cancelOrder(req));
    }

    public Order getOrder(GetOrderRequest req) {
        return wrapCall((Callable<Order>) () -> client.getOrder(req));
    }

    public MarketPair[] receivePairs() {
        return wrapCall((Callable<MarketPair[]>) () -> client.receivePairs());
    }

    public  Candle[] getHistoricRates(GetHistoryRatesRequest req) {
        return wrapCall((Callable<Candle[]>) () -> client.getHistoricRates(req));
    }

    public void subscribeTrades(String market, Consumer<TradesResponse> onTrades) {
        tradeSubscriptions.put(market, onTrades);
        client.subscribeTrades(market, onTrades);

    }
    public void subscribeError(Consumer<OpenLimitsException> onError) {
        client.subscribeError(onError);
    }
    public void subscribeDisconnect(Runnable onDisconnect) {
        client.subscribeDisconnect(onDisconnect);
    }

    public void disconnect() {
        client.disconnect();
    }

    private <T> T wrapCall(Callable<T> callable) {
        int MAX_RETRY_LIMIT = 5;
        String lastErrorMessage = "";
        for (int i = 0; i < MAX_RETRY_LIMIT; i++) {
            try {
                return callable.call();
            }
            catch(NashProtocolError error) {
                lastErrorMessage = error.getMessage();
                buildClient();
                try {
                    Thread.sleep(1000);
                }
                catch (Exception e){}
            }
            catch(Exception error) {
            }
        }
        throw new OpenLimitsException("Exceeded maximum retry limit of " + MAX_RETRY_LIMIT + " retries on Nash client. " + lastErrorMessage);
    }
}
