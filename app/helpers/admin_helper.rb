module AdminHelper

  #true for tags with a name longer than 50chars or containing a semi-colon, comma, forward slash, colon or pipe character
  def dubious_tag?(tag)
    tag.text.length>50 || [";",",",":","/","|"].detect{|c| tag.text.include?(c)}
  end
  
  def admin_mail_to_links   
    result=""
    admins=Person.admins
    admins.each do |person|
      result << mail_to(h(person.email),h(person.name))
      result << ", " unless admins.last==person
    end
    return result.html_safe
  end
  
  #takes the terms and scores received from SearchStats, and generates a string
  def search_terms_summary terms_and_scores    
    return "<span class='none_text'>No search queries during this period</span>".html_safe if terms_and_scores.empty?
    words=terms_and_scores.collect{|ts| "#{h(ts[0])}(#{ts[1]})" }
    words.join(", ").html_safe
  end

  def delayed_job_status
    status = ""
    begin
      pids = [0,1].collect do |n|
        Daemons::PidFile.new("#{Rails.root}/tmp/pids","delayed_job.#{n.to_s}")
      end
      pids.each do |pid|
        if pid.running?
          status << "Running [Process ID: #{pid.pid}]"
        else
          status << "<span class='error_text'>Not running</span>"
        end
        status << "&nbsp;:&nbsp;" unless pid == pids.last
      end

    rescue Exception=>e
      status = "<span class='error_text'>Unable to determine current status - #{e.message}</span>"
    end
    status.html_safe
  end

  def action_buttons user_or_person, action
    case action
      when "activate"
        if user_or_person.is_a?(User) && user_or_person.person
          admin_activate_user_button = button_link_to("Activate now", 'activate', activate_path(:activation_code => user_or_person.activation_code))
          resend_activation_email_button = button_link_to("Resend activation email", 'message', resend_activation_email_user_path(user_or_person), :method => :post)
          admin_activate_user_button + ' ' + resend_activation_email_button
        end
      when "delete"
        button_link_to("Delete", 'destroy', user_or_person, {:method => :delete, :confirm => "Are you sure you wish to delete this #{user_or_person.class.name}?"})
      else
        nil
    end
  end

  def admin_text_setting(name, value, title, description = nil, options = {})
    admin_setting_block(title, description) do
      text_field_tag(name, value, options.merge!(:class => 'form-control'))
    end
  end

  def admin_textarea_setting(name, value, title, description = nil, options = {})
    admin_setting_block(title, description) do
      text_area_tag(name, value, options.merge!(:rows => 5, :class => 'form-control'))
    end
  end

  def admin_file_setting(name, title, description = nil, options = {})
    admin_setting_block(title, description) do
      file_field_tag(name, options)
    end
  end

  def admin_password_setting(name, value, title, description = nil, options = {})
    admin_setting_block(title, description) do
      password_field_tag(name, value, options.merge!(:autocomplete => 'off', :class => 'form-control'))
    end
  end

  def admin_checkbox_setting(name, value, checked, title, description = nil, options = {})
    content_tag(:div, :class => 'checkbox') do
      content_tag(:label, :class => 'admin-checkbox') do
        check_box_tag(name, value, checked, options) + title.html_safe
      end +
          (description ? content_tag(:p, description.html_safe, :class => 'help-block') : ''.html_safe)
    end
  end

  def admin_dropdown_setting(name, option_tags, title, description = nil, options = {})
    admin_setting_block(title, description) do
      #   select_tag "people", "<option>David</option>".html_safe
      #   # => <select id="people" name="people"><option>David</option></select>
      select_tag(name, option_tags, options)
    end
  end

  private

  def admin_setting_block(title, description)
    content_tag(:div, :class => 'form-group') do
      content_tag(:label, title) +
          (description ? content_tag(:p, description.html_safe, :class => 'help-block') : ''.html_safe) +
          yield
    end
  end

end
