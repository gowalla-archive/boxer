# Boxer

Boxer is a template engine for creating nested and multi-view JSON objects
from Ruby hashes.

<section style="text-align:center">
  <a href="http://engineering.gowalla.com/2011/10/24/boxer/">
    <img src="http://engineering.gowalla.com/images/boxer.png" alt="Logo" />
  </a>
</section>

## The Problem

Say you have a couple ActiveRecord models in your Rails app and you want to
render an API response in JSON, but the view of each of those model objects
may change based on the API action that's being requested.

 * User
 * Place

For instance, the API for `GET /users/:id` should render a full representation
of the User object in question, including all relevant attributes.

But in your `GET /places/:id/users` API call, you only need short-form
representations of the users at that place, without every single attribute
being included in the response.

## The Solution

Boxer allows you to define a box for each type of object you'd like to display
(or for each amalgamation of objects you want to display&mdash;it's up to you).

    Boxer.box(:user) do |box, user|
      {
        :name => user.name,
        :age  => user.age,
      }
    end

To display different views on the same object, you can use Boxer's views:

    Boxer.box(:user) do |box, user|
      box.view(:base) do
        {
          :name => user.name,
          :age  => user.age,
        }
      end

      box.view(:full, :extends => :base) do
        {
          :email      => user.email,
          :is_private => user.private?,
        }
      end
    end

As you might guess, the `:full` view includes all attributes in the `:base`
view by virtue of the `:extends` option.

Now, in order to render a User with the `:base` view, simple call `Boxer.ship`:

    Boxer.ship(:user, User.first)

Boxer assumes that you want the `:base` view if no view is specified to
`ship`&mdash;it's the only specially-named view.

To render the full view for the same user:

    Boxer.ship(:user, User.first, :view => :full)

Which will give you back a Ruby hash on which you can call `#to_json`, to render
your JSON response<sup>1</sup>:

    >> Boxer.ship(:user, User.first, :view => :full).to_json
    => "{"name": "Bo Jim", "age": 17, "email": "b@a.com", "is_private": false}"

Composing different boxes together is as simple as calling `Boxer.ship` from
within a box&mdash;it's just Ruby:

    Boxer.box(:place) do |box, place|
      {
        :name     => place.name,
        :address  => place.address,
        :top_user => Boxer.ship(:user, place.users.order(:visits).first),
      }
    end

 1. `Hash#to_json` requires a [json library](http://rubygems.org/gems/json)

## More Features

See [the wiki](/gowalla/boxer/wiki) for more features of Boxer, including:

 * [Extra Arguments](/gowalla/boxer/wiki/Extra-Arguments)
 * [Preconditions](/gowalla/boxer/wiki/Preconditions)
 * [Helper Methods in Boxes](/gowalla/boxer/wiki/Helper-Methods-in-Boxes)
 * [Box Includes](/gowalla/boxer/wiki/Box-Includes)
 * [Multiple Inheritance](/gowalla/boxer/wiki/Multiple-Inheritance)

## Installation

Install the [boxer gem](http://rubygems.org/gems/boxer).

## Original Author

 * [Brad Fults](http://h3h.net/), [Gowalla Incorporated](http://gowalla.com/)

## Inspiration

Boxer was inspired by [RABL](https://github.com/nesquena/rabl),
by [Nathan Esquenazi](https://github.com/nesquena).
