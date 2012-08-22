require 'open-uri'
@blocks = {
  :roman => {
    :digits => (0x0030..0x0039).to_a,
    :latin => (0x0041..0x005A).to_a.push((0x0061..0x007A).to_a).flatten,
    :greek => (0x0391..0x03A9).to_a.push(0x2207). # push nabla
      fill(0x03F4,17,1).          # put Theta into the reserved slot
      push((0x03B1..0x03C9).to_a. # small greek
      push(0x2202, 0x03F5, 0x03D1, 0x03F0, 0x03D5, 0x03F1, 0x03D6)).
      # partial, varepsilon, vartheta, varkappa, phi, varrho, and varpi
      flatten },
  "math alnum symbols" => {
    "bold" => {
      :latin => (0x1D400..0x1D433).to_a,
      :greek => (0x1D6A8..0x1D6E1).to_a,
      :digits => (0x1D7CE..0x1D7D7).to_a },
    "italic" => {
      :latin => (0x1D434..0x1D467).to_a.fill(0x210E,33,1), # h
      :greek => (0x1D6E2..0x1D71B).to_a },
    "bold italic" => {
      :latin => (0x1D468..0x1D49B).to_a,
      :greek => (0x1D71C..0x1D755).to_a },
    "script" => {
      :latin => (0x1D49C..0x1D4CF).to_a.fill(
        0x212C,1,1).fill(  # B
        0x2130,4,1).fill(  # E
        0x2131,5,1).fill(  # F
        0x210B,7,1).fill(  # H
        0x2110,8,1).fill(  # I
        0x2112,11,1).fill( # L
        0x2133,12,1).fill( # M
        0x211B,17,1).fill( # R
        0x212F,30,1).fill( # e
        0x210A,32,1).fill( # g
        0x2134,40,1) },    # o
    "script bold" => { :latin => (0x1D4D0..0x1D503).to_a },
    "fraktur" => {
      :latin => (0x1D504..0x1D537).to_a.fill(
        0x212D,2,1).fill(  # C
        0x210C,7,1).fill(  # H
        0x2111,8,1).fill(  # I
        0x211C,17,1).fill( # R
        0x2128,25,1) },    # Z
    "double-struck" => {
      :latin => (0x1D538..0x1D56B).to_a.fill(
        0x2102,2,1).fill(  # C
        0x210D,7,1).fill(  # H
        0x2115,13,1).fill( # N
        0x2119,15,1).fill( # P
        0x211A,16,1).fill( # Q
        0x211D,17,1).fill( # R
        0x2124,25,1),      # Z
      :digits => (0x1D7D8..0x1D7E1).to_a },
    "fraktur bold" => { :latin => (0x1D56C..0x1D59F).to_a },
    "sans-serif" => {
      :latin => (0x1D5A0..0x1D5D3).to_a,
      :digits => (0x1D7E2..0x1D7EB).to_a },
    "sans-serif bold" => {
      :latin => (0x1D5D4..0x1D607).to_a,
      :greek => (0x1D756..0x1D78F).to_a,
      :digits => (0x1D7EC..0x1D7F5).to_a },
    "sans-serif italic" => { :latin => (0x1D608..0x1D63B).to_a },
    "sans-serif bold italic" => {
      :latin => (0x1D63C..0x1D66F).to_a,
      :greek => (0x1D790..0x1D7C9).to_a },
    "monospace" => {
      :latin => (0x1D670..0x1D6A3).to_a,
      :digits => (0x1D7F6..0x1D7FF).to_a }
  }
}

if ARGV.any? {|arg| arg == '--maps'}
  @blocks["math alnum symbols"].each do |fam,range|
    file = File.open("#{fam}.map", 'w')
    file.puts "LHSName \"#{fam}\"\nRHSName \"UNICODE\"\npass(unicode)"
    range.map {|key,val| @blocks[:roman][key].zip(val) }.each do |f|
      f.each {|pair| file.puts pair.map {|i| "U+%04X" % i.to_s }.join(" > ")}
    end
    file.close
    `teckit_compile "#{file.path}"` if `which teckit_compile`
  end
end

@barbaras_table = "#{ENV['HOME']}/stix-tbl.ascii-2006-10-20.txt"
# http://www.ams.org/STIX/bnb/stix-tbl.ascii-2006-10-20

@classes = {
  "A" => '"7"0', # Alphabetic
  "B" => '"2"0', # Binary
  "C" => '"5"0', # Closing; Usually paired with opening delimiter
  "D" => '"7"0', # Diacritic
  "F" => '"0"0', # Fence
  "G" => '"0"0', # Glyph_Part; Pieces for assembling large operators, brackets or arrows
  "L" => '"1"0', # Large; N-ary or Large operator, often takes limits
  "N" => '"0"0', # Normal; This includes all digits and symbols requiring only one form
  "O" => '"4"0', # Opening; Usually paired with closing delimiter
  "P" => '"6"0', # Punctuation
  "R" => '"3"0', # Relational; Includes arrows
  "S" => '"6"0', # Space; Space character
  "U" => '"0"0', # Unary; Unary operators
  "V" => '"0"0', # Vary; Operators that can be unary or binary
  "X" => '"0"0'  # Special; Compatibility character
}

@commands = Array.new
open(@barbaras_table).each_with_index do |line,index|
  break if index > 2837 # We'll handle the math alnum block later
  next  if index < 3    # Skip the headers
  @commands << line.split.select do |words|
    words =~ /(\\|(0x)?[0-9A-F]{4,}|\b[#{@classes.keys.join}]\b)/i #and
      #words !~ /(text|Bb|scr|frak)/i # skip the fam's and text stuff
  end
end
  
if ARGV.any? {|arg| arg == '--cmds'}
  @commands.map {|items| # Clean up the input
    [ items.first.sub(/[^0-9A-F]/i,''), # remove non-hex stuff from the codepoint
      items.select {|c| c =~ /^[#{@classes.keys.join}]$/}.first, # class
      items.select {|c| c =~ /\\/}]}. # command name and possible aliases
  reject {|r| r.any? {|r| r.nil? or r.empty?}}.
  map {|cp,cls,cmds|
    [cp, cls, cmds.shift.sub(/^[^\\]+/,'')] + cmds unless cmds.empty?}.
  uniq.each do |cp,cls,cmd,shrt|
    puts case cls
      when "D"     : "\\def#{cmd}{\\XeTeXmathaccent#{@classes[cls]}\"#{cp} }"
      when /[FOC]/ : "\\def#{cmd}{\\XeTeXdelimiter#{@classes[cls]}\"#{cp} }"
      else "\\XeTeXmathchardef#{cmd}#{@classes[cls]}\"#{cp}"
    end unless cmd =~ /^\\\d/
    puts "\\let#{shrt}#{cmd}" if shrt and shrt != cmd and
      shrt !~ /\\not/ and shrt =~ /^\\/
  end

  %w(Alpha Beta Gamma Delta Epsilon Zeta Eta varTheta Iota Kappa Lambda
    Mu Nu Xi Omicron Pi Rho Theta Sigma Tau Upsilon Phi Chi Psi Omega nabla
    alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi
    omicron pi rho varsigma sigma tau upsilon varphi chi psi omega
    partial varepsilon vartheta varkappa phi varrho varpi).
    zip(@blocks[:roman][:greek]).each_with_index do |(cmd,cp),i|
      puts "\\XeTeXmathchardef\\#{cmd}=\"7\"#{i < 26 ? 0 : 1}\"#{"%04X" % cp}"
  end
end
