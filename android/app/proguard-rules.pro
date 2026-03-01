# mailer package rules
-keep class javax.mail.** { *; }
-keep class javax.activation.** { *; }
-keep class com.sun.mail.** { *; }
-keep class org.apache.james.mime4j.** { *; }

# If using google_fonts or pdf which sometimes need basic keeps
-keep class com.google.fonts.** { *; }
-keep class pw.widgets.** { *; }
-keep class pdf.** { *; }
