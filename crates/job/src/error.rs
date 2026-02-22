use std::{fmt::Display, string::FromUtf8Error};

#[derive(Debug)]
pub enum RenderRssError {
    Template(su_template::RenderTemplateError),
    TimeFormat(time::error::Format),
    Utf8(FromUtf8Error),
    Rss(rss::Error),
}

impl From<FromUtf8Error> for RenderRssError {
    fn from(err: FromUtf8Error) -> Self {
        Self::Utf8(err)
    }
}

impl From<rss::Error> for RenderRssError {
    fn from(err: rss::Error) -> Self {
        Self::Rss(err)
    }
}

impl From<time::error::Format> for RenderRssError {
    fn from(err: time::error::Format) -> Self {
        Self::TimeFormat(err)
    }
}

impl From<su_template::RenderTemplateError> for RenderRssError {
    fn from(err: su_template::RenderTemplateError) -> Self {
        Self::Template(err)
    }
}

impl Display for RenderRssError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self)
    }
}
