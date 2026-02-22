use axum::response::Html;

pub fn render_index(
    template_handle: &su_template::Handle,
    assigns: model::job::IndexPage,
    filters: model::job::IndexFilters,
) -> Result<Html<String>, su_template::RenderTemplateError> {
    let context = minijinja::context! {
        filters => filters,
        assigns => assigns,
    };

    let html = template_handle.render_template(context, "pages/index_job.html")?;
    Ok(Html(html))
}

pub fn render_index_partial(
    template_handle: &su_template::Handle,
    jobs: Vec<model::job::Job>,
) -> Result<Html<String>, su_template::RenderTemplateError> {
    let context = minijinja::context! {jobs => jobs};
    let html = template_handle.render_template(context, "partials/job_entries.html")?;
    Ok(Html(html))
}

pub fn render_view(
    template_handle: &su_template::Handle,
    assigns: model::job::ViewPage,
    query: Option<&str>,
) -> Result<Html<String>, su_template::RenderTemplateError> {
    let context = minijinja::context! {
        assigns => assigns,
        query => query,
    };

    let html = template_handle.render_template(context, "pages/view_job.html")?;
    Ok(Html(html))
}

pub fn render_index_rss(
    template_handle: &su_template::Handle,
    jobs: Vec<model::job::Job>,
) -> Result<String, crate::error::RenderRssError> {
    let mut items: Vec<rss::Item> = Vec::new();

    for job in jobs.iter() {
        let guid = rss::GuidBuilder::default()
            .value(format!(
                "{}-{}",
                job.updated_at.unix_timestamp_nanos(),
                job.id
            ))
            .permalink(false)
            .build();

        let assigns = minijinja::context! {
            job => job,
        };

        let context = minijinja::context! {
            assigns => assigns,
        };

        let content = template_handle.render_template(context, "partials/job_details.html")?;

        let item = rss::ItemBuilder::default()
            .title(job.position.clone())
            .category(job.category_name.as_str().into())
            .author(job.company_name.clone())
            .content(content)
            .link(format!(
                "https://www.remotehiro.com/jobs/{}-{}?utm_medium=rss",
                slug::slugify(job.position.as_str()),
                job.id
            ))
            .pub_date(
                job.created_at
                    .format(&time::format_description::well_known::Rfc2822)?,
            )
            .guid(guid)
            .build();

        items.push(item);
    }

    let channel = rss::ChannelBuilder::default()
        .title("remotehiro jobs")
        .link("https://www.remotehiro.com")
        .description("find work, anywhere")
        .items(items)
        .language("en".to_string())
        .atom_ext(Some(rss::extension::atom::AtomExtension {
            links: vec![rss::extension::atom::Link {
                rel: "self".into(),
                href: "https://remotehiro.com".to_string(),
                ..Default::default()
            }],
        }))
        .build();

    let utf8 = channel.write_to(Vec::new())?;
    let xml = String::from_utf8(utf8)?;
    Ok(xml)
}
