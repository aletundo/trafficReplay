package com.piggymetrics.notification.filter.utils;

import com.piggymetrics.notification.domain.Recipient;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AbstractionUtils {
  public static final String REQUEST_ABSTRACTION = "0";
  public static final String RESPONSE_ABSTRACTION = "1";

  public static final String GET_CURRENT_NOTIFICATIONS_SETTINGS_ABSTRACTION = "0";
  public static final String SAVE_CURRENT_NOTIFICATIONS_SETTINGS_ABSTRACTION = "1";

  public static final Map<String, String> statusCodeAbstractions = buildStatusCodeAbstractions();
  public static final Map<String, String> stringAbstractions = buildStringAbstractions();
  public static final Map<String, String> mapAbstractions = buildMapAbstractions();
  public static final Map<String, String> listAbstractions = buildListAbstractions();
  public static final Map<String, String> objectRefAbstractions = buildObjectRefAbstractions();

  private static final String NULL = "NULL";
  private static final String EMPTY = "EMPTY";
  private static final String NOT_EMPTY = "NOT_EMPTY";
  private  static final String NOT_NULL = "NOT_NULL";

  private static final String INFORMATIONAL_RESPONSE = "1xx";
  private static final String SUCCESSFUL = "2xx";
  private static final String REDIRECTION = "3xx";
  private static final String CLIENT_ERROR = "4xx";
  private static final String SERVER_ERROR = "5xx";

  public static Map<String, String> buildStatusCodeAbstractions() {
    Map<String, String> map = new HashMap<>();

    map.put(INFORMATIONAL_RESPONSE, "0");
    map.put(SUCCESSFUL, "1");
    map.put(REDIRECTION, "2");
    map.put(CLIENT_ERROR, "3");
    map.put(SERVER_ERROR, "4");

    return map;
  }

  public static Map<String, String> buildStringAbstractions() {
    Map<String, String> map = new HashMap<>();

    map.put(NULL, "0");
    map.put(EMPTY, "1");
    map.put(NOT_EMPTY, "2");

    return map;
  }

  public static Map<String, String> buildMapAbstractions() {
    Map<String, String> map = new HashMap<>();

    map.put(NULL, "0");
    map.put(EMPTY, "1");
    map.put(NOT_EMPTY, "2");

    return map;
  }

  public static Map<String, String> buildListAbstractions() {
    Map<String, String> map = new HashMap<>();

    map.put(NULL, "0");
    map.put(EMPTY, "1");
    map.put(NOT_EMPTY, "2");

    return map;
  }

  public static Map<String, String> buildObjectRefAbstractions() {
    Map<String, String> map = new HashMap<>();

    map.put(NULL, "0");
    map.put(NOT_NULL, "1");

    return map;
  }

  public static String abstractRecipient(final Recipient recipient) {
    String symbol = "";

    if (null == recipient.getAccountName()) {
      symbol+= stringAbstractions.get(NULL);
    } else if (recipient.getAccountName().isEmpty()) {
      symbol+= stringAbstractions.get(EMPTY);
    } else {
      symbol+= stringAbstractions.get(NOT_EMPTY);
    }

    // email @NotNull
    symbol+= abstractEmail(recipient.getEmail());

    if (null == recipient.getScheduledNotifications()) {
      symbol+= mapAbstractions.get(NULL);
    } else if (recipient.getScheduledNotifications().isEmpty()) {
      symbol+= mapAbstractions.get(EMPTY);
    } else {
      symbol+= mapAbstractions.get(NOT_EMPTY);
    }

    return symbol;
  }

  private static String abstractEmail(String email) {
    // email @NotNull
    if (null == email) {
      return "0";
    } else {
      return "1";
    }
  }

  public static String abstractStatusCode(final int statusCode) {
    if (statusCode >= 100 && statusCode < 200) {
      return statusCodeAbstractions.get(INFORMATIONAL_RESPONSE);
    } else if (statusCode >= 200 && statusCode < 300) {
      return statusCodeAbstractions.get(SUCCESSFUL);
    } else if (statusCode >= 300 && statusCode < 400) {
      return statusCodeAbstractions.get(REDIRECTION);
    } else if (statusCode >= 400 && statusCode < 500) {
      return statusCodeAbstractions.get(CLIENT_ERROR);
    } else {
      return statusCodeAbstractions.get(SERVER_ERROR);
    }
  }

  public static String abstractList(final List<?> list) {
    if (null == list) {
      return listAbstractions.get(NULL);
    } else if (list.isEmpty()) {
      return listAbstractions.get(EMPTY);
    } else {
      return listAbstractions.get(NOT_EMPTY);
    }
  }
}
