static HX_REQUEST: http::HeaderName = http::HeaderName::from_static("hx-request");
static HX_PRELOADED: http::HeaderName = http::HeaderName::from_static("hx-preloaded");

#[derive(Clone, Copy, Debug)]
pub struct HxRequest(pub bool);

#[derive(Clone, Copy, Debug)]
pub struct HxPreloaded(pub bool);

impl headers::Header for HxRequest {
    fn name() -> &'static http::HeaderName {
        &HX_REQUEST
    }

    fn decode<'i, I>(values: &mut I) -> Result<Self, headers::Error>
    where
        Self: Sized,
        I: Iterator<Item = &'i http::HeaderValue>,
    {
        let default_value = http::HeaderValue::from_static("false");
        let value = values.next().unwrap_or(&default_value);
        Ok(HxRequest(value == "true"))
    }

    fn encode<E: Extend<http::HeaderValue>>(&self, values: &mut E) {
        let s = if self.0 { "true" } else { "false" };
        let value = http::HeaderValue::from_static(s);
        values.extend(std::iter::once(value));
    }
}

impl headers::Header for HxPreloaded {
    fn name() -> &'static http::HeaderName {
        &HX_PRELOADED
    }

    fn decode<'i, I>(values: &mut I) -> Result<Self, headers::Error>
    where
        Self: Sized,
        I: Iterator<Item = &'i http::HeaderValue>,
    {
        let default_value = http::HeaderValue::from_static("false");
        let value = values.next().unwrap_or(&default_value);
        Ok(HxPreloaded(value == "true"))
    }

    fn encode<E: Extend<http::HeaderValue>>(&self, values: &mut E) {
        let s = if self.0 { "true" } else { "false" };
        let value = http::HeaderValue::from_static(s);
        values.extend(std::iter::once(value));
    }
}
