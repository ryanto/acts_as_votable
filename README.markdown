# Acts As Votable (aka Acts As Likeable)

Acts As Votable is a Ruby Gem specifically written for Rails/ActiveRecord models.
The main goals of this gem are:

- Allow any model to be voted on, like/dislike, upvote/downvote, etc.
- Allow any model to be voted under arbitrary scopes.
- Allow any model to vote.  In other words, votes do not have to come from a user,
  they can come from any model (such as a Group or Team).
- Provide an easy to write/read syntax.

## Installation

### Rails 3+

Just add the following to your Gemfile.

    gem 'acts_as_votable', '~> 0.5.0'

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

Active Record scopes are provided to make life easier.

    @post.votes.up.by_type(User)
    @post.votes.down
    @user1.votes.up
    @user1.votes.down
    @user1.votes.up.by_type(Post)

Once scoping is complete, you can also trigger a get for the
voter/votable

    @post.votes.up.by_type(User).voters
    @post.votes.down.by_type(User).voters

    @user.votes.up.for_type(Post).votables
    @user.votes.up.votables

You can also 'unvote' a model to remove a previous vote.

    @post.liked_by @user1
    @post.unliked_by @user1

    @post.disliked_by @user1
    @post.undisliked_by @user1

Unvoting works for both positive and negative votes.

### Examples with scopes

You can add an scope to your vote

    # positive votes
    @post.liked_by @user1, :vote_scope => 'rank'
    @post.vote :voter => @user3, :vote_scope => 'rank'
    @post.vote :voter => @user5, :vote => 'like', :vote_scope => 'rank'

    # negative votes
    @post.downvote_from @user2, :vote_scope => 'rank'
    @post.vote :voter => @user2, :vote => 'bad', :vote_scope => 'rank'

    # tally them up!
    @post.find_votes(:vote_scope => 'rank').size # => 5
    @post.likes(:vote_scope => 'rank').size # => 3
    @post.upvotes(:vote_scope => 'rank').size # => 3
    @post.dislikes(:vote_scope => 'rank').size # => 2
    @post.downvotes(:vote_scope => 'rank').size # => 2

    # votable model can be voted under different scopes
    # by the same user
    @post.vote :voter => @user1, :vote_scope => 'week'
    @post.vote :voter => @user1, :vote_scope => 'month'

    @post.votes.size # => 2
    @post.find_votes(:vote_scope => 'week').size # => 1
    @post.find_votes(:vote_scope => 'month').size # => 1

### The Voter

You can have your voters ``acts_as_voter`` to provide some reserve functionality.

    class User < ActiveRecord::Base
      acts_as_voter
    end

    @user.likes @article

    @article.votes.size # => 1
    @article.likes.size # => 1
    @article.dislikes.size # => 0

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

You can also check whether the voter has voted up or down.

    @user.likes @comment1
    @user.dislikes @comment2
    # user has not voted on @comment3

    @user.voted_up_on? @comment1 # => true
    @user.voted_down_on? @comment1 # => false

    @user.voted_down_on? @comment2 # => true
    @user.voted_up_on? @comment2 # => false

    @user.voted_up_on? @comment3 # => false
    @user.voted_down_on? @comment3 # => false

Aliases for methods ``voted_up_on?`` and ``voted_down_on?`` are: ``voted_up_for?``, ``voted_down_for?``, ``liked?`` and ``disliked?``.

Also, you can obtain a list of all the objects a user has voted for.
This returns the actual objects instead of instances of the Vote model.
All objects are eager loaded

    @user.find_voted_items

    @user.find_up_voted_items
    @user.find_liked_items

    @user.find_down_voted_items
    @user.find_disliked_items

Members of an individual model that a user has voted for can also be
displayed. The result is an ActiveRecord Relation.

    @user.get_voted Comment

    @user.get_up_voted Comment

    @user.get_down_voted Comment

### Registered Votes

Voters can only vote once per model.  In this example the 2nd vote does not count
because @user has already voted for @shoe.

    @user.likes @shoe
    @user.likes @shoe

    @shoe.votes # => 1
    @shoe.likes # => 1

To check if a vote counted, or registered, use vote_registered? on your model
after voting.  For example:

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
        add_column :posts, :cached_votes_score, :integer, :default => 0
        add_column :posts, :cached_votes_up, :integer, :default => 0
        add_column :posts, :cached_votes_down, :integer, :default => 0
        add_index  :posts, :cached_votes_total
        add_index  :posts, :cached_votes_score
        add_index  :posts, :cached_votes_up
        add_index  :posts, :cached_votes_down
      end

      def self.down
        remove_column :posts, :cached_votes_total
        remove_column :posts, :cached_votes_score
        remove_column :posts, :cached_votes_up
        remove_column :posts, :cached_votes_down
      end
    end

## Testing

All tests follow the RSpec format and are located in the spec directory

## TODO

- Pass in a block of options when creating acts_as.  Allow for things
  like disabling the aliasing

- Smarter language syntax.  Example: ``@user.likes`` will return all of the votables
that the user likes, while ``@user.likes @model`` will cast a vote for @model by
@user.

- Need to test a model that is votable as well as a voter

- The aliased methods are referred to by using the terms 'up/down' and/or
'true/false'.  Need to come up with guidelines for naming these methods.

- Create more aliases. Specifically for counting votes and finding votes.
