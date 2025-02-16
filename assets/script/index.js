const html = {
  getToggleFiltersButton: () => document.querySelector("#toggle-filters"),
  getFiltersForm: () => document.querySelector("#filters"),
  getJobsTableBody: () => document.querySelector(".jobs > tbody"),

  getFieldsetCheckbox: (id) => document.querySelector(`fieldset > legend input[id=${id}][type=checkbox]`),
  getFieldsetsCheckboxes: () => document.querySelectorAll(`fieldset > legend input[id][type=checkbox]`),

  getFieldsetOptions: (name, opts) => {
    let query = `input[name=${name}][type=checkbox]`;
    if (opts.isChecked != null && opts.isChecked) {
      query = `${query}:checked`
    }
    if (opts.isChecked != null && !opts.isChecked) {
      query = `${query}:not(:checked)`
    }
    return document.querySelectorAll(query);
  },
};

const FETCH_TIMEOUT = 150;

html.getToggleFiltersButton()?.addEventListener("click", (e) => {
  let filtersForm = html.getFiltersForm();

  if (filtersForm.style.display == "block") {
    filtersForm.style.display = "none";
  } else {
    filtersForm.style.display = "block";
  }
});

html.getFiltersForm()?.addEventListener("input", (e) => {
  // If it's a fieldset checkbox, then we toggle all of the checkboxes in the
  // fieldset whose `name` matches the ID.
  if (e.target.type == "checkbox" && e.target.id != "") {
    let checkboxes = document.querySelectorAll(`input[name=${e.target.id}][type=checkbox]`);
    checkboxes.forEach((el) => el.checked = e.target.checked);
  } else if (e.target.type == "checkbox" && e.target.name != "") {
    let fieldsetCheckbox = html.getFieldsetCheckbox(e.target.name);
    let uncheckedBoxes = html.getFieldsetOptions(e.target.name, {"isChecked": false});
    let checkedBoxes = html.getFieldsetOptions(e.target.name, {"isChecked": true});
    fieldsetCheckbox.indeterminate = uncheckedBoxes.length >= 1 && checkedBoxes.length >= 1;
    fieldsetCheckbox.checked = checkedBoxes.length >= 1 && uncheckedBoxes.length == 0;
  }

  setTimeout(() => submitForm(html.getFiltersForm()), FETCH_TIMEOUT);
});

async function submitForm(form) {
  const data = new FormData(form);
  const queryParams = new URLSearchParams(data);

  // Push new query parameters to history
  const url = new URL(location);

  url.search = "";
  queryParams.entries().forEach(([k,v]) => {
    if (v != "") {
      url.searchParams.append(k, v);
    }
  });

  history.pushState({}, "", url);

  // Dispatch request and replace content
  const res = await fetch(form.action + '?' + queryParams.toString(), {
    method: "GET",
    headers: {
      'Hx-Request': 'true'
    }
  });

  let htmlRes = await res.text();
  html.getJobsTableBody().innerHTML = htmlRes;
}


let fieldsetCheckboxes = html.getFieldsetsCheckboxes();

fieldsetCheckboxes.forEach(el => {
  let uncheckedBoxes = html.getFieldsetOptions(el.id, {"isChecked": false});
  let checkedBoxes = html.getFieldsetOptions(el.id, {"isChecked": true});
  el.indeterminate = uncheckedBoxes.length >= 1 && checkedBoxes.length >= 1
});
