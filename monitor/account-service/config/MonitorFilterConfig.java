package com.piggymetrics.account.config;

import com.piggymetrics.account.filter.MonitorFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MonitorFilterConfig {

  private static final String ENDPOINT = "/*";

  @Bean
  public FilterRegistrationBean<MonitorFilter> monitorFilterEnhancedBean() {
    FilterRegistrationBean<MonitorFilter> registrationBean = new FilterRegistrationBean<>();
    registrationBean.setFilter(new MonitorFilter());
    registrationBean.addUrlPatterns(ENDPOINT);
    registrationBean.setOrder(-101);
    return registrationBean;
  }
}
