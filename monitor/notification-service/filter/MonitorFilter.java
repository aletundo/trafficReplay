package com.piggymetrics.notification.filter;

import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.piggymetrics.notification.domain.Recipient;
import com.piggymetrics.notification.filter.utils.AbstractionUtils;
import com.piggymetrics.notification.filter.utils.wrapper.SpringRequestWrapper;
import com.piggymetrics.notification.filter.utils.wrapper.SpringResponseWrapper;
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
import org.springframework.web.filter.OncePerRequestFilter;

public class MonitorFilter extends OncePerRequestFilter {

  private static final Logger LOGGER = LoggerFactory.getLogger(MonitorFilter.class);
  private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

  private static final String GET_CURRENT_NOTIFICATIONS_SETTINGS_PATH = "/notifications/recipients/current";
  private static final String SAVE_CURRENT_NOTIFICATIONS_SETTINGS_PATH = "/notifications/recipients/current";

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
    final String method = request.getMethod();
    final String URI = request.getRequestURI();

    LOGGER.info("{} {}", method, URI);

    switch (method) {
      case "GET":
        if (GET_CURRENT_NOTIFICATIONS_SETTINGS_PATH.equals(URI)) {
          return prefix + buildGetCurrentNotificationsSettingsSymbolRequest(request);
        }
      case "PUT":
        if (SAVE_CURRENT_NOTIFICATIONS_SETTINGS_PATH.equals(URI)) {
          return prefix + buildSaveCurrentNotificationsSettingsSymbolRequest(request);
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

    LOGGER.info("{} {}", method, URI);

    switch (method) {
      case "GET":
        if (GET_CURRENT_NOTIFICATIONS_SETTINGS_PATH.equals(URI)) {
          return prefix + buildGetCurrentNotificationsSettingsSymbolResponse(request, response);
        }
      case "PUT":
        if (SAVE_CURRENT_NOTIFICATIONS_SETTINGS_PATH.equals(URI)) {
          return prefix + buildSaveCurrentNotificationsSettingsSymbolResponse(request, response);
        }
    }
    return prefix;
  }

  private String buildGetCurrentNotificationsSettingsSymbolRequest(SpringRequestWrapper request) {
    return AbstractionUtils.GET_CURRENT_NOTIFICATIONS_SETTINGS_ABSTRACTION;
  }

  private String buildGetCurrentNotificationsSettingsSymbolResponse(SpringRequestWrapper request, SpringResponseWrapper response)
      throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final Recipient recipient = OBJECT_MAPPER.readValue(inputStreamToString(request.getInputStream(), request.getCharacterEncoding()), Recipient.class);
      payload = AbstractionUtils.abstractRecipient(recipient);
    } catch (JsonMappingException | JsonParseException ignored) {}

    return AbstractionUtils.GET_CURRENT_NOTIFICATIONS_SETTINGS_ABSTRACTION + statusCode + payload;
  }

  private String buildSaveCurrentNotificationsSettingsSymbolRequest(SpringRequestWrapper request)
      throws IOException {
    String payload = "";
    try {
      final Recipient recipient = OBJECT_MAPPER.readValue(inputStreamToString(request.getInputStream(), request.getCharacterEncoding()), Recipient.class);
      payload = AbstractionUtils.abstractRecipient(recipient);
    } catch (JsonMappingException | JsonParseException ignored) {}

    return AbstractionUtils.SAVE_CURRENT_NOTIFICATIONS_SETTINGS_ABSTRACTION + payload;
  }

  private String buildSaveCurrentNotificationsSettingsSymbolResponse(SpringRequestWrapper request, SpringResponseWrapper response)
      throws IOException {
    final String statusCode = AbstractionUtils.abstractStatusCode(response.getStatus());
    String payload = "";
    try {
      final Recipient recipient = OBJECT_MAPPER.readValue(inputStreamToString(request.getInputStream(), request.getCharacterEncoding()), Recipient.class);
      payload = AbstractionUtils.abstractRecipient(recipient);
    } catch (JsonMappingException | JsonParseException ignored) {}

    return AbstractionUtils.SAVE_CURRENT_NOTIFICATIONS_SETTINGS_ABSTRACTION + statusCode + payload;
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
