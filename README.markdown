### Major Updates

Version 0.1.0 introduces new and refactored function calls that improve the
natural language syntax of this gem.  Certain calls that were compatible with
version 0.0.5 will now be broken.  Remember to specify a the version in your
Gemfile to prevent functionality breakdowns between versions.

In version 0.1.0 functions like ``@post.votes`` return an array of all of the vote
records for @post.  In order to count the number of votes simply use
``@post.votes.size`` now.

- - -

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

    @post.liked_by @user
    @post.votes.size # => 1

### Like/Dislike Yes/No Up/Down

Here are some voting examples.  All of these calls are valid and acceptable.  The
more natural calls are the first few examples.

    @post.liked_by @user1
    @post.downvote_from @user2
    @post.vote :voter => @user3
    @post.vote :voter => @user4, :vote => 'bad'
    @post.vote :voter => @user5, :vote => 'like'


By default all votes are positive, so @user3 has cast a 'good' vote for @post.

@user1, @user3, and @user5 all voted in favor of @post.

@user2 and @user4 on the other had has voted against @post.


Just about any word works for casting a vote in favor or against post.  Up/Down,
Like/Dislike, Positive/Negative... the list goes on-and-on.  Boolean flags ``true`` and
``false`` are also applicable.

Revisiting the previous example of code.

    # positive votes
    @post.liked_by @user1
    @post.vote :voter => @user3
    @post.vote :voter => @user5, :vote => 'like'

    # negative votes
    @post.downvote_from @user2
    @post.vote :voter => @user2, :vote => 'bad'
    
    # tally them up!
    @post.votes.size # => 5
    @post.likes.size # => 3
    @post.upvotes.size # => 3
    @post.dislikes.size # => 2
    @post.downvotes.size # => 2

### The Voter

You can have your voters ``acts_as_voter`` to provide some reserve functionality.

    class User < ActiveRecord::Base
      acts_as_voter
    end

    @user.likes @article

    @article.votes.size # => 1
    @article.likes.size # => 1
    @article.downvotes.size # => 0

To check if a voter has voted on a model, you can use ``voted_for?``.  You can
check how the voter voted by using ``voted_as_when_voted_for``.

    @user.likes @comment1
    @user.up_votes @comment2
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

    @user.likes @shoe
    @user.upvotes @shoe

    @shoe.votes # => 1
    @shoe.likes # => 1

To check if a vote counted, or registered, use vote_registered? on your model
directly after voting.  For example:

    @hat.liked_by @user
    @hat.vote_registered? # => true

    @hat.liked_by => @user
    @hat.vote_registered? # => false, because @user has already voted this way

    @hat.disliked_by @user
    @hat.vote_registered? # => true, because user changed their vote

    @hat.votes.size # => 1
    @hat.positives.size # => 0
    @hat.negatives.size # => 1

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

## TODO

- Smarter language syntax.  Example: ``@user.likes`` will return all of the votables
that the user likes, while ``@user.likes @model`` will cast a vote for @model by
@user.

- Need to test a model that is votable as well as a voter

- The aliased functions are referred to by using the terms 'up/down' amd/or
'true/false'.  Need to come up with guidelines for naming these function.

- Create more aliases. Specifically for counting votes and finding votes.
