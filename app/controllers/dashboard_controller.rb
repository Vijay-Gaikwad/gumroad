# frozen_string_literal: true

class DashboardController < Sellers::BaseController
  include ActionView::Helpers::NumberHelper, CurrencyHelper

  before_action :check_payment_details, only: :index

  layout "inertia", only: :index

  def index
    authorize :dashboard

    if current_seller.suspended_for_tos_violation?
      redirect_to products_url
    else
      LargeSeller.create_if_warranted(current_seller)
      presenter = CreatorHomePresenter.new(pundit_user)
      props_data = presenter.creator_home_props.merge(
        show_passkey_prompt: current_user.passkey_prompt_eligible? && current_user.role_owner_for?(current_seller)
      )

      render inertia: "Dashboard/Index",
             props: { creator_home: props_data }
    end
  end

  def dismiss_passkey_prompt
    authorize :dashboard, :index?

    current_user.update!(passkey_prompt_dismissed_at: Time.current)

    head :ok
  end

  def customers_count
    authorize :dashboard

    count = current_seller.all_sales_count
    render json: { success: true, value: number_with_delimiter(count) }
  end

  def total_revenue
    authorize :dashboard

    revenue = current_seller.gross_sales_cents_total_as_seller
    render json: { success: true, value: formatted_dollar_amount(revenue) }
  end

  def active_members_count
    authorize :dashboard

    count = current_seller.active_members_count
    render json: { success: true, value: number_with_delimiter(count) }
  end

  def monthly_recurring_revenue
    authorize :dashboard

    revenue = current_seller.monthly_recurring_revenue
    render json: { success: true, value: formatted_dollar_amount(revenue) }
  end

  def download_tax_form
    authorize :dashboard

    year = Time.current.year - 1
    tax_form_download_url = current_seller.tax_form_1099_download_url(year:)
    return redirect_to tax_form_download_url, allow_other_host: true if tax_form_download_url.present?

    flash[:alert] = "A 1099 form for #{year} was not filed for your account."
    redirect_to dashboard_path
  end

  def dismiss_getting_started_checklist
    authorize :dashboard

    current_seller.update!(has_dismissed_getting_started_checklist: true)

    head :ok
  end
end
