package com.piggymetrics.account.filter;

import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.piggymetrics.account.domain.Account;
import com.piggymetrics.account.domain.User;
import com.piggymetrics.account.filter.utils.AbstractionUtils;
import com.piggymetrics.account.filter.utils.wrapper.SpringRequestWrapper;
import com.piggymetrics.account.filter.utils.wrapper.SpringResponseWrapper;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
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

  private static final String GET_ACCOUNT_BY_NAME_PATH = "/accounts/{name}";
  private static final String GET_CURRENT_ACCOUNT_PATH = "/accounts/current";
  private static final String SAVE_CURRENT_ACCOUNT_PATH = "/accounts/current";
  private static final String CREATE_NEW_ACCOUNT_PATH = "/accounts/";

  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {

    final SpringRequestWrapper wrappedRequest = new SpringRequestWrapper(request);
    LOGGER.info("Request symbol: {}", buildRequestSymbol(wrappedRequest));

    final SpringResponseWrapper wrappedResponse = new SpringResponseWrapper(response);
    try {
      chain.doFilter(wrappedRequest, wrappedResponse);
    } catch (Exception e) {
      wrappedResponse.setStatus(500);
      LOGGER.info("Response symbol: {}", buildResponseSymbol(wrappedRequest, wrappedResponse));
      throw e;
    }
    LOGGER.info("Response symbol: {}", buildResponseSymbol(wrappedRequest, wrappedResponse));
  }

  private String buildRequestSymbol(SpringRequestWrapper request) throws IOException {
    final String prefix = AbstractionUtils.REQUEST_ABSTRACTION;

    // Select endpoint
    String method = request.getMethod();
    String URI = request.getRequestURI();

    LOGGER.info("{} {}", method, URI);

    switch (method) {
      case "GET":
        if (GET_CURRENT_ACCOUNT_PATH.equals(URI)) {
          return prefix + buildGetCurrentAccountSymbolRequest(request);
        } else if (URI.startsWith("/accounts/") && 2 == StringUtils.countOccurrencesOf(URI, "/")) {
          return prefix + buildGetAccountByNameSymbolRequest(request);
        }
      case "POST":
        if (CREATE_NEW_ACCOUNT_PATH.equals(URI)) {
          return prefix + buildCreateNewAccountSymbolRequest(request);
        }
      case "PUT":
        if (SAVE_CURRENT_ACCOUNT_PATH.equals(URI)) {
          return prefix + buildSaveCurrentAccountSymbolRequest(request);
        }
    }
    return prefix;
  }

  private String buildResponseSymbol(SpringRequestWrapper request, SpringResponseWrapper response)
      throws IOException {
    final String prefix = AbstractionUtils.RESPONSE_ABSTRACTION;

    // Select endpoint
    String method = request.getMethod();
    String URI = request.getRequestURI();

    LOGGER.info("{} {}", method, URI);

    switch (method) {
      case "GET":
        if (GET_CURRENT_ACCOUNT_PATH.equals(URI)) {
          return prefix + buildGetCurrentAccountSymbolResponse(request, response);
        } else if (URI.startsWith("/accounts/") && 2 == StringUtils.countOccurrencesOf(URI, "/")) {
          return prefix + buildGetAccountByNameSymbolResponse(request, response);
        }
      case "POST":
        if (CREATE_NEW_ACCOUNT_PATH.equals(URI)) {
          return prefix + buildCreateNewAccountSymbolResponse(request, response);
        }
      case "PUT":
        if (SAVE_CURRENT_ACCOUNT_PATH.equals(URI)) {
          return prefix + buildSaveCurrentAccountSymbolResponse(request, response);
        }
    }
    return prefix;
  }

  private String buildGetAccountByNameSymbolRequest(SpringRequestWrapper request) {
    return AbstractionUtils.GET_ACCOUNT_BY_NAME_ABSTRACTION;
  }

  private String buildGetAccountByNameSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final Account account =
          OBJECT_MAPPER.readValue(
              byteArrayToString(
                  response.getContentAsByteArray(), response.getCharacterEncoding()),
              Account.class);
      payload = AbstractionUtils.abstractAccount(account);
    } catch (JsonMappingException | JsonParseException ignored) {
      LOGGER.error("{}", ignored.getMessage());
    }

    return AbstractionUtils.GET_ACCOUNT_BY_NAME_ABSTRACTION + statusCode + payload;
  }

  private String buildGetCurrentAccountSymbolRequest(SpringRequestWrapper request) {
    return AbstractionUtils.GET_CURRENT_ACCOUNT_ABSTRACTION;
  }

  private String buildGetCurrentAccountSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final Account account =
          OBJECT_MAPPER.readValue(
              byteArrayToString(
                  response.getContentAsByteArray(), response.getCharacterEncoding()),
              Account.class);
      payload = AbstractionUtils.abstractAccount(account);
    } catch (JsonMappingException | JsonParseException ignored) {
      LOGGER.error("{}", ignored.getMessage());
    }

    return AbstractionUtils.GET_CURRENT_ACCOUNT_ABSTRACTION + statusCode + payload;
  }

  private String buildSaveCurrentAccountSymbolRequest(SpringRequestWrapper request) throws IOException{
    String payload = "";
    try {
      final Account account =
          OBJECT_MAPPER.readValue(
              inputStreamToString(
                  request.getInputStream(), request.getCharacterEncoding()),
              Account.class);
      payload = AbstractionUtils.abstractAccount(account);
    } catch (JsonMappingException | JsonParseException e) {
      LOGGER.error("JsonMappingException | JsonParseException: {}", e.getMessage());
    }

    return AbstractionUtils.SAVE_CURRENT_ACCOUNT_ABSTRACTION + payload;
  }

  private String buildSaveCurrentAccountSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final Account account =
          OBJECT_MAPPER.readValue(
              byteArrayToString(
                  response.getContentAsByteArray(), response.getCharacterEncoding()),
              Account.class);
      payload = AbstractionUtils.abstractAccount(account);
    } catch (JsonMappingException | JsonParseException e) {
      LOGGER.error("JsonMappingException | JsonParseException: {}", e.getMessage());
    }

    return AbstractionUtils.SAVE_CURRENT_ACCOUNT_ABSTRACTION + statusCode + payload;
  }

  private String buildCreateNewAccountSymbolRequest(SpringRequestWrapper request)
      throws IOException {
    String payload = "";
    try {
      final User user =
          OBJECT_MAPPER.readValue(
              inputStreamToString(
                  request.getInputStream(), request.getCharacterEncoding()),
              User.class);
      payload = AbstractionUtils.abstractUser(user);
    } catch (JsonMappingException | JsonParseException e) {
      LOGGER.error("JsonMappingException | JsonParseException: {}", e.getMessage());
    }

    return AbstractionUtils. CREATE_NEW_ACCOUNT_ABSTRACTION + payload;
  }

  private String buildCreateNewAccountSymbolResponse(
      SpringRequestWrapper request, SpringResponseWrapper response) throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final Account account =
          OBJECT_MAPPER.readValue(
              byteArrayToString(
                  response.getContentAsByteArray(), response.getCharacterEncoding()),
              Account.class);
      payload = AbstractionUtils.abstractAccount(account);
    } catch (JsonMappingException | JsonParseException e) {
      LOGGER.error("JsonMappingException | JsonParseException: {}", e.getMessage());
    }

    return AbstractionUtils.CREATE_NEW_ACCOUNT_ABSTRACTION + statusCode + payload;
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
    LOGGER.info(
        "Request: method={}, uri={}, payload={}",
        wrappedRequest.getMethod(),
        wrappedRequest.getRequestURI(),
        inputStreamToString(
            wrappedRequest.getInputStream(), wrappedRequest.getCharacterEncoding()));
  }

  private void logResponse(SpringRequestWrapper wrappedRequest, SpringResponseWrapper wrappedResponse, int overriddenStatus)
      throws IOException {
    wrappedResponse.setCharacterEncoding("UTF-8");
    LOGGER.info(
        "Response: method={}, uri={}, status={}, payload={}",
        wrappedRequest.getMethod(),
        wrappedRequest.getRequestURI(),
        overriddenStatus,
        byteArrayToString(
            wrappedResponse.getContentAsByteArray(), wrappedResponse.getCharacterEncoding()));
  }
}
