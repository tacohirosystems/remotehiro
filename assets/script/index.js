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

  getTagsSearchInput: () => document.querySelector("#tags-search"),
  getCountriesSearchInput: () => document.querySelector("#countries-search"),

  filterOptions: (query, selectorName, datasetName) => {
    let rows = document.querySelectorAll(selectorName);
    rows.forEach(row => {
      if (!fuzzysearch(query, row.dataset[datasetName]) && query) {
        row.style.display = "none";
      } else {
        row.style.display = "";
      }
    })
  }
};

const FETCH_TIMEOUT = 400;

// Source: https://github.com/bevacqua/fuzzysearch
function fuzzysearch (needle, haystack) {
  var hlen = haystack.length;
  var nlen = needle.length;
  if (nlen > hlen) {
    return false;
  }
  if (nlen === hlen) {
    return needle === haystack;
  }
  outer: for (var i = 0, j = 0; i < nlen; i++) {
    var nch = needle.charCodeAt(i);
    while (j < hlen) {
      if (haystack.charCodeAt(j++) === nch) {
        continue outer;
      }
    }
    return false;
  }
  return true;
}

// On page load
let submitTicker = null;

html.getToggleFiltersButton()?.addEventListener("click", (e) => {
  let filtersForm = html.getFiltersForm();

  if (filtersForm.style.display == "block") {
    filtersForm.style.display = "none";
  } else {
    filtersForm.style.display = "block";
  }
});

html.getFiltersForm()?.addEventListener("input", (e) => {
  if (submitTicker != null) {
    clearTimeout(submitTicker);
  }

  let isTextInput = e.target.type == "text" || e.target.type == "search" || e.target.type == "number";
  let delay = isTextInput ? FETCH_TIMEOUT : 0;

  let form = html.getFiltersForm();
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
  submitTicker = setTimeout(() => submitForm(toFormData(form), form.action), delay);
});

function toFormData(form) {
  const formData = new FormData(form);
  let minSalary = formData.get("min_salary");

  if (minSalary && parseInt(minSalary) <= 0) {
    formData.delete("min_salary");
  }

  formData.entries().forEach(([k, v]) => {
    if (v == "") {
      formData.delete(k);
    }
  });
  return formData;
}

async function submitForm(formData, action) {
  console.log(formData);
  const queryParams = new URLSearchParams(formData);

  // Push new query parameters to history
  const url = new URL(location);

  url.search = "";
  queryParams.entries().forEach(([k,v]) => {
    url.searchParams.append(k, v);
  });

  history.pushState({}, "", url);

  // Dispatch request and replace content
  const res = await fetch(action + '?' + queryParams.toString(), {
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

html.getTagsSearchInput().addEventListener("input", (e) => {
  html.filterOptions(html.getTagsSearchInput().value?.toLowerCase(), ".tag[data-tag-name]", "tagName");
});

html.getCountriesSearchInput().addEventListener("input", (e) => {
  html.filterOptions(html.getCountriesSearchInput().value?.toLowerCase(), ".country[data-country-name]", "countryName");
});
