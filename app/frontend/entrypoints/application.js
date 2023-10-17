// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
console.log('Vite ⚡️ Rails')

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

console.log('Visit the guide for more information: ', 'https://vite-ruby.netlify.app/guide/rails')

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

import * as Credential from "@/credential";

function postForm(e, callback) {
    const data = new URLSearchParams()
    for (const pair of new FormData(e.target)) {
        data.append(pair[0], pair[1])
    }
    fetch(e.target.action, { method: 'post', body: data }).then((data) => {
        data.json().then(callback)
    })
}

$('body.registrations.new form').on('submit', (e) => {
    postForm(e, (credentialOptions => {
        if (credentialOptions.errors)
            $('.alert').removeClass('hide').text(credentialOptions.errors)
        else
            Credential.create(encodeURI('/registration/callback'), credentialOptions)
    }))
    return false
})

$('body.sessions.new form').on('submit', (e) => {
    postForm(e, (credentialOptions) => {
        if (credentialOptions.error)
            $('.alert').removeClass('hide').text(credentialOptions.error)
        else
            Credential.get(credentialOptions)
    })
    return false
})
