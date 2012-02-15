#!/usr/bin/env ruby

# Created: February 12, 2012
# A little program to traverse the Ottawa Fringe schedule and
# find an attendance plan that lets someone see all the shows

# Class representing a showtime for a play
# available - this slot is still available to see a play
# attended - this slot has been chosen to attend the associated play

class Showtime
	attr_accessor :day, :hour, :available, :attended

	def initialize(day, hour)
		@day = day
		@hour = hour
		@available = true
		@attended = false
	end
	
	def mark_attended
		@attended = true
	end
	
	def mark_unavailable
		@available = false
	end
end

# Class representing a play
# num_avail - number of timeslots still available to choose from
# attended - whether or not a timeslot has been chosen for this play

class Show
	attr_accessor :num_avail, :title, :venue, :times, :attended
	
	def initialize(title, venue)
		@title = title
		@venue = venue
		@num_avail = 0;
		@attended = false;
		@times = [];
	end
	
	def add_showtime(day, hour)
		@times.push(Showtime.new(day, hour))
		@num_avail += 1
	end

	def print_showtimes
		@times.each do |time|
			if (time.attended)
				puts "Attending at this time:"
			end
			puts "Playing at #{time.hour} on #{time.day}"
		end
	end	
	
	def get_available
		@times.each do |time|
			if (time.available)
				return time
			end
		end
	end
	
	def mark_time_unavailable(day, hour)
		@times.each do |showtime|
			if ((day == showtime.day) && ((showtime.hour - hour).abs <= 0.5) && showtime.available)
				showtime.mark_unavailable
				@num_avail -= 1
			end
		end
	end
end

# Sample shows to test the program
# Code to read it in from a file will go here eventually

schedule = []

schedule.push(Show.new("Uno","Venue1"))
schedule.last.add_showtime(16, 7)
schedule.last.add_showtime(17, 6.5)

schedule.push(Show.new("Dos","Venue1"))
schedule.last.add_showtime(16, 7)
schedule.last.add_showtime(17, 7.5)

schedule.push(Show.new("Tres","Venue2"))
schedule.last.add_showtime(16, 7)

schedule.push(Show.new("Quattro","Venue2"))
schedule.last.add_showtime(16, 8)
schedule.last.add_showtime(17, 7)

# Variable to track how many shows have not been scheduled
unscheduled = schedule.length

# Keep scheduling until all the plays have slots assigned
while unscheduled > 0
	# Sort schedule by number of showtimes available
	schedule = schedule.sort {|x,y| x.num_avail > y.num_avail ? 1 : -1}

	# Mark the first available showtime in the first unattended play as attended - why not?
	i = 0
	while schedule[i].attended
		i += 1
	end
	this_time =	schedule[i].get_available
	this_time.mark_attended
	schedule[i].attended = true
	unscheduled -= 1

	# Mark this slot as unattended for all other plays
	schedule[i+1..-1].each do |play|
		# puts "Checking #{play.title}"
		play.mark_time_unavailable(this_time.day, this_time.hour)
	end
end

# Print out plays
schedule.each do |play|
	puts play.title, play.venue
	play.print_showtimes
end
