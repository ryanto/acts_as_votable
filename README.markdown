# Acts As Votable (aka Acts As Likeable)

Acts As Votable is a Ruby Gem specifically written for Rails/ActiveRecord models.
The main goals of this gem are:

- Allow any model to be voted on, like/dislike, upvote/downvote, etc.
- Allow any model to vote.  In other words, votes do not have to come from a user,
  they can come from any model (such as a Group or Team).
- Provide an easy to write natural language syntax.

## Installation

### Rails 3

Just add the following to your Gemfile.

    gem 'acts_as_votable'

And follow that up with a ``bundle install``.

### Database Migrations

Acts As Votable uses a votes table to store all voting information.  To
generate and run the migration just use.

    rails generate acts_as_votable:migration
    rake db:migrate

You will get a performance increase by adding in cached columns to your model's
tables.  You will have to do this manually through your own migrations.  See the
caching section of this document for more information.

## Usage

### Votable Models

    class Post < ActiveRecord::Base
      acts_as_votable
    end

    @post = Post.new(:name => 'my post!')
    @post.save

    @post.vote :voter => @user
    @post.votes # => 1

### Like/Dislike Yes/No Up/Down

    @post.vote :voter => @user1
    @post.vote :voter => @user2, :vote => 'bad'
    @post.vote :voter => @user3, :vote => 'like'

By default all votes are positive, so @user1 has cast a 'good' vote for @post.

@user2 on the other had has voted against @post.  This is a 'bad' vote.

@user3 has voted in favor of @post.

Just about any word works for casting a vote in favor or against post.  Good/Bad,
Up/Down, Like/Dislike, the list goes on-and-on.  Boolean flags ``true`` and
``false`` are also applicable.

Revisiting the previous example of code.

    @post.vote :voter => @user1
    @post.vote :voter => @user2, :vote => 'bad'
    @post.vote :voter => @user3, :vote => 'like'

    @post.votes # => 3
    @post.likes # => 2
    @post.upvotes # => 2
    @post.dislikes # => 1
    @post.downvotes # => 1

### The Voter

When voting on a model you need to provide a ``:voter => @the_voter_model``.  95%
of the time, this will be @user.  You can have your voters ``acts_as_voter``
to provide some reserve functionality.

    class User < ActiveRecord::Base
      acts_as_voter
    end

    @user.vote :votable => @article

    @article.votes # => 1
    @article.ups # => 1
    @article.downs # => 0

To check if a voter has voted on a model, you can use ``voted_for?``.  You can
check how the voter voted by using ``voted_as_when_voted_for``.

    @user.vote :votable => @comment1, :vote => 'yes'
    @user.vote :votable => @comment2, :vote => 'dislike'
    # user has not voted on @comment3

    @user.voted_for? @comment1 # => true
    @user.voted_for? @comment2 # => true
    @user.voted_for? @comment3 # => false

    @user.voted_as_when_voted_for @comment1 # => true, he liked it
    @user.voted_as_when_voted_for @comment2 # => false, he didnt like it
    @user.voted_as_when_voted_for @comment3 # => nil, he has yet to vote

### Registered Votes

Voters can only vote once per model.  In this example the 2nd vote does not count
because @user has already voted for @shoe.

    @shoe.vote :voter => @user, :vote => 'like'
    @shoe.vote :voter => @user, :vote => 'yes'

    @shoe.votes # => 1
    @shoe.likes # => 1

To check if a vote counted, or registered, use vote_registered? on your model
directly after voting.  For example:

    @hat.vote :voter => @user
    @hat.vote_registered? # => true

    @hat.vote :voter => @user
    @hat.vote_registered? # => false, because @user has already voted this way

    @hat.vote :voter => @user, :vote => 'bad'
    @hat.vote_registered? # => true, because user changed their vote

    @hat.votes # => 1
    @hat.goods # => 0
    @hat.bads # => 1

## Caching

To speed up perform you can add cache columns to your votable model's table.  These
columns will automatically be updated after each vote.  For example, if we wanted
to speed up @post we would use the following migration:

    class AddCachedVotesToPosts < ActiveRecord::Migration
      def self.up
        add_column :posts, :cached_votes_total, :integer, :default => 0
        add_column :posts, :cached_votes_up, :integer, :default => 0
        add_column :posts, :cached_votes_down, :integer, :default => 0
        add_index  :posts, :cached_votes_total
        add_index  :posts, :cached_votes_up
        add_index  :posts, :cached_votes_down
      end

      def self.down
        remove_column :posts, :cached_votes_total
        remove_column :posts, :cached_votes_up
        remove_column :posts, :cached_votes_down
      end
    end

## Testing

All tests follow the RSpec format and are located in the spec directory

## Thanks

A huge thank you to Michael Bleigh and his Acts-As-Taggable-On gem.  I learned
how to write gems by following his source code.
