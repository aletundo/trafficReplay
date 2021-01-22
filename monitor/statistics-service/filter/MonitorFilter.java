package com.piggymetrics.statistics.filter;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.piggymetrics.statistics.domain.Account;
import com.piggymetrics.statistics.domain.timeseries.DataPoint;
import com.piggymetrics.statistics.filter.utils.AbstractionUtils;
import com.piggymetrics.statistics.filter.utils.wrapper.SpringRequestWrapper;
import com.piggymetrics.statistics.filter.utils.wrapper.SpringResponseWrapper;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.util.List;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletInputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.codehaus.jackson.JsonParseException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

public class MonitorFilter extends OncePerRequestFilter {

  private static final Logger LOGGER = LoggerFactory.getLogger(MonitorFilter.class);
  private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

  private static final String GET_CURRENT_ACCOUNT_STATISTICS_PATH = "/statistics/current";
  private static final String GET_STATISTICS_BY_ACCOUNT_NAME_PATH = "/statistics/{accountName}";
  private static final String SAVE_ACCOUNT_STATISTICS_PATH = "/statistics/{accountName}";

  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {

    final SpringRequestWrapper wrappedRequest = new SpringRequestWrapper(request);
    LOGGER.info("{}", buildRequestSymbol(wrappedRequest));

    final SpringResponseWrapper wrappedResponse = new SpringResponseWrapper(response);
    try {
      chain.doFilter(wrappedRequest, wrappedResponse);
    } catch (Exception e) {
      wrappedResponse.setStatus(500);
      LOGGER.info("{}", buildResponseSymbol(wrappedRequest, wrappedResponse));
      throw e;
    }
    LOGGER.info("{}", buildResponseSymbol(wrappedRequest, wrappedResponse));
  }

  private String buildRequestSymbol(SpringRequestWrapper request) throws IOException {
    final String prefix = AbstractionUtils.REQUEST_ABSTRACTION;

    // Select endpoint
    final String method = request.getMethod();
    final String URI = request.getRequestURI();

    LOGGER.debug("{} {}", method, URI);

    switch (method) {
      case "GET":
        if (GET_CURRENT_ACCOUNT_STATISTICS_PATH.equals(URI)) {
          return prefix + buildGetCurrentAccountStatisticsSymbolRequest(request);
        } else if (URI.startsWith("/statistics/") && 2 == StringUtils.countOccurrencesOf(URI, "/")) {
          return prefix + buildGetStatisticsByAccountNameSymbolRequest(request);
        }
      case "PUT":
        if (URI.startsWith("/statistics/") && 2 == StringUtils.countOccurrencesOf(URI, "/")) {
          return prefix + buildSaveAccountStatisticsSymbolRequest(request);
        }
    }

    return prefix;
  }

  private String buildResponseSymbol(SpringRequestWrapper request, SpringResponseWrapper response)
      throws IOException {
    final String prefix = AbstractionUtils.RESPONSE_ABSTRACTION;

    // Select endpoint
    final String method = request.getMethod();
    final String URI = request.getRequestURI();

    LOGGER.debug("{} {}", method, URI);

    switch (method) {
      case "GET":
        if (GET_CURRENT_ACCOUNT_STATISTICS_PATH.equals(URI)) {
          return prefix + buildGetCurrentAccountStatisticsSymbolResponse(request, response);
        } else if (URI.startsWith("/statistics/") && 2 == StringUtils.countOccurrencesOf(URI, "/")) {
          return prefix + buildGetStatisticsByAccountNameSymbolResponse(request, response);
        }
      case "PUT":
        if (URI.startsWith("/statistics/") && 2 == StringUtils.countOccurrencesOf(URI, "/")) {
          return prefix + buildSaveAccountStatisticsSymbolResponse(request, response);
        }
    }

    return prefix;
  }

  private String buildGetCurrentAccountStatisticsSymbolRequest(SpringRequestWrapper request) {
    return AbstractionUtils.GET_CURRENT_ACCOUNT_STATISTICS_ABSTRACTION;
  }

  private String buildGetCurrentAccountStatisticsSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final List<DataPoint> statistics =
          OBJECT_MAPPER.readValue(
              byteArrayToString(
                  response.getContentAsByteArray(), response.getCharacterEncoding()), new TypeReference<List<DataPoint>>(){});
      payload = AbstractionUtils.abstractList(statistics);
    } catch (JsonMappingException | JsonParseException ignored) {
      LOGGER.debug("{}", ignored.getMessage());
    }

    return AbstractionUtils.GET_CURRENT_ACCOUNT_STATISTICS_ABSTRACTION + statusCode + payload;
  }

  private String buildGetStatisticsByAccountNameSymbolRequest(SpringRequestWrapper request) {
    return AbstractionUtils.GET_STATISTICS_BY_ACCOUNT_NAME_ABSTRACTION;
  }

  private String buildGetStatisticsByAccountNameSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final List<DataPoint> statistics =
          OBJECT_MAPPER.readValue(
              byteArrayToString(
                  response.getContentAsByteArray(), response.getCharacterEncoding()), new TypeReference<List<DataPoint>>(){});
      payload = AbstractionUtils.abstractList(statistics);
    } catch (JsonMappingException | JsonParseException ignored) {
      LOGGER.debug("{}", ignored.getMessage());
    }

    return AbstractionUtils.GET_STATISTICS_BY_ACCOUNT_NAME_ABSTRACTION + statusCode + payload;
  }

  private String buildSaveAccountStatisticsSymbolRequest(SpringRequestWrapper request)
      throws IOException {
    String payload = "";
    try {
      final Account account =
          OBJECT_MAPPER.readValue(
              inputStreamToString(
                  request.getInputStream(), request.getCharacterEncoding()), Account.class);
      payload = AbstractionUtils.abstractAccount(account);
    } catch (JsonMappingException | JsonParseException ignored) {
      LOGGER.debug("{}", ignored.getMessage());
    }
    return AbstractionUtils.SAVE_ACCOUNT_STATISTICS_ABSTRACTION + payload;
  }

  private String buildSaveAccountStatisticsSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    return AbstractionUtils.SAVE_ACCOUNT_STATISTICS_ABSTRACTION + statusCode ;
  }

  private String inputStreamToString(ServletInputStream inputStream, String characterEncoding)
      throws IOException {
    ByteArrayOutputStream result = new ByteArrayOutputStream();
    byte[] buffer = new byte[1024];
    int length;
    while ((length = inputStream.read(buffer)) != -1) {
      result.write(buffer, 0, length);
    }
    return result.toString(characterEncoding);
  }

  private String byteArrayToString(byte[] bytes, String characterEncoding) {
    return new String(bytes, Charset.forName(characterEncoding));
  }

  private void logRequest(SpringRequestWrapper wrappedRequest) throws IOException {
    LOGGER.debug(
        "Request: method={}, uri={}, payload={}",
        wrappedRequest.getMethod(),
        wrappedRequest.getRequestURI(),
        inputStreamToString(
            wrappedRequest.getInputStream(), wrappedRequest.getCharacterEncoding()));
  }

  private void logResponse(SpringRequestWrapper wrappedRequest, SpringResponseWrapper wrappedResponse, int overriddenStatus)
      throws IOException {
    wrappedResponse.setCharacterEncoding("UTF-8");
    LOGGER.debug(
        "Response: method={}, uri={}, status={}, payload={}",
        wrappedRequest.getMethod(),
        wrappedRequest.getRequestURI(),
        overriddenStatus,
        byteArrayToString(
            wrappedResponse.getContentAsByteArray(), wrappedResponse.getCharacterEncoding()));
  }
}
