package com.piggymetrics.notification.filter.utils.wrapper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import javax.servlet.ReadListener;
import javax.servlet.ServletInputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;

public class SpringRequestWrapper extends HttpServletRequestWrapper {

  private byte[] body;

  public SpringRequestWrapper(HttpServletRequest request) {
    super(request);
    try {
      ByteArrayOutputStream buffer = new ByteArrayOutputStream();
      int nRead;
      byte[] data = new byte[1024];
      while ((nRead = request.getInputStream().read(data, 0, data.length)) != -1) {
        buffer.write(data, 0, nRead);
      }
      buffer.flush();
      body = buffer.toByteArray();
    } catch (IOException ex) {
      body = new byte[0];
    }
  }

  @Override
  public ServletInputStream getInputStream() throws IOException {
    return new ServletInputStream() {
      ByteArrayInputStream byteArray = new ByteArrayInputStream(body);

      public boolean isFinished() {
        return false;
      }

      public boolean isReady() {
        return true;
      }

      public void setReadListener(ReadListener readListener) {}

      @Override
      public int read() throws IOException {
        return byteArray.read();
      }
    };
  }
}
