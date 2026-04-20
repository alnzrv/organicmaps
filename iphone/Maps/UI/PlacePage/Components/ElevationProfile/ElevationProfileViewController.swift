import Chart

protocol ElevationProfileViewProtocol: AnyObject {
  var presenter: ElevationProfilePresenterProtocol? { get set }

  var userInteractionEnabled: Bool { get set }
  var isChartViewHidden: Bool { get set }
  var isChartViewInfoHidden: Bool { get set }
  var canReceiveUpdates: Bool { get }

  func setChartData(_ data: ChartPresentationData)
  func setActivePointDistance(_ distance: Double)
  func setMyPositionDistance(_ distance: Double)
  func reloadDescription()
}

final class ElevationProfileViewController: UIViewController {
  private enum Constants {
    static let chartViewInsets = UIEdgeInsets(top: 12, left: 16, bottom: 0, right: -16)
    static let chartViewVisibleHeight: CGFloat = 176
    static let descriptionCollectionViewHeight: CGFloat = 44
    static let graphViewContainerInsets = UIEdgeInsets(top: -4, left: 0, bottom: 0, right: 0)
  }

  var chartHeight: CGFloat = Constants.chartViewVisibleHeight {
    didSet {
      guard chartHeight != oldValue else { return }
      reloadConstraints()
    }
  }

  var chartInsets: UIEdgeInsets = Constants.chartViewInsets {
    didSet {
      guard chartInsets != oldValue else { return }
      reloadConstraints()
    }
  }

  var presenter: ElevationProfilePresenterProtocol?

  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var chartView = ChartView()
  private var graphViewContainer = UIView()
  private var descriptionCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = 0
    return UICollectionView(frame: .zero, collectionViewLayout: layout)
  }()

  private var chartViewBottomConstraint: NSLayoutConstraint!
  private var chartViewLeadingConstraint: NSLayoutConstraint!
  private var chartViewTrailingConstraint: NSLayoutConstraint!
  private var chartViewHeightConstraint: NSLayoutConstraint!
  private var descriptionCollectionViewViewTopConstraint: NSLayoutConstraint!
  private var descriptionCollectionViewViewLeadingConstraint: NSLayoutConstraint!
  private var descriptionCollectionViewViewTrailingConstraint: NSLayoutConstraint!

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    layoutViews()
    presenter?.configure()
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    descriptionCollectionView.reloadData()
  }

  // MARK: - Private methods

  private func setupViews() {
    view.setStyle(.background)
    setupDescriptionCollectionView()
    setupChartView()
  }

  private func setupChartView() {
    graphViewContainer.translatesAutoresizingMaskIntoConstraints = false
    chartView.translatesAutoresizingMaskIntoConstraints = false
    chartView.onSelectedPointChanged = { [weak self] in
      self?.presenter?.onSelectedPointChanged($0)
    }
  }

  private func setupDescriptionCollectionView() {
    descriptionCollectionView.backgroundColor = .clear
    descriptionCollectionView.register(cell: ElevationProfileDescriptionCell.self)
    descriptionCollectionView.dataSource = presenter
    descriptionCollectionView.delegate = presenter
    descriptionCollectionView.isScrollEnabled = false
    descriptionCollectionView.translatesAutoresizingMaskIntoConstraints = false
    descriptionCollectionView.showsHorizontalScrollIndicator = false
    descriptionCollectionView.showsVerticalScrollIndicator = false
  }

  private func layoutViews() {
    view.addSubview(descriptionCollectionView)
    graphViewContainer.addSubview(chartView)
    view.addSubview(graphViewContainer)

    chartViewLeadingConstraint = chartView.leadingAnchor.constraint(equalTo: graphViewContainer.leadingAnchor, constant: chartInsets.left)
    chartViewTrailingConstraint = chartView.trailingAnchor.constraint(equalTo: graphViewContainer.trailingAnchor, constant: chartInsets.right)
    chartViewBottomConstraint = chartView.bottomAnchor.constraint(equalTo: graphViewContainer.bottomAnchor, constant: chartInsets.bottom)
    chartViewHeightConstraint = chartView.heightAnchor.constraint(equalToConstant: chartHeight)
    descriptionCollectionViewViewTopConstraint = descriptionCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: chartInsets.top)
    descriptionCollectionViewViewLeadingConstraint = descriptionCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: chartInsets.left)
    descriptionCollectionViewViewTrailingConstraint = descriptionCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: chartInsets.right)
    NSLayoutConstraint.activate([
      descriptionCollectionViewViewTopConstraint,
      descriptionCollectionViewViewLeadingConstraint,
      descriptionCollectionViewViewTrailingConstraint,
      descriptionCollectionView.heightAnchor.constraint(equalToConstant: Constants.descriptionCollectionViewHeight),
      descriptionCollectionView.bottomAnchor.constraint(equalTo: graphViewContainer.topAnchor, constant: Constants.graphViewContainerInsets.top),
      graphViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      graphViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      graphViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      chartViewLeadingConstraint,
      chartViewTrailingConstraint,
      chartView.topAnchor.constraint(equalTo: graphViewContainer.topAnchor),
      chartViewBottomConstraint,
      chartViewHeightConstraint,
    ])
  }

  private func reloadConstraints() {
    guard isViewLoaded else { return }
    let wasChartHidden = isChartViewHidden
    chartViewHeightConstraint.constant = wasChartHidden ? .zero : chartHeight
    chartViewLeadingConstraint.constant = chartInsets.left
    chartViewTrailingConstraint.constant = chartInsets.right
    descriptionCollectionViewViewTopConstraint.constant = chartInsets.top
    descriptionCollectionViewViewLeadingConstraint.constant = chartInsets.left
    descriptionCollectionViewViewTrailingConstraint.constant = chartInsets.right
    presenter?.configure()
    isChartViewHidden = wasChartHidden
    reloadDescription()
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }

  private func getPreviewHeight() -> CGFloat {
    view.height - descriptionCollectionView.frame.minY
  }
}

// MARK: - ElevationProfileViewProtocol

extension ElevationProfileViewController: ElevationProfileViewProtocol {
  var userInteractionEnabled: Bool {
    get { chartView.isUserInteractionEnabled }
    set { chartView.isUserInteractionEnabled = newValue }
  }

  var isChartViewHidden: Bool {
    get { chartView.isHidden }
    set {
      chartView.isHidden = newValue
      graphViewContainer.isHidden = newValue
      chartViewHeightConstraint.constant = newValue ? .zero : chartHeight
    }
  }

  var isChartViewInfoHidden: Bool {
    get { chartView.isChartViewInfoHidden }
    set { chartView.isChartViewInfoHidden = newValue }
  }

  var canReceiveUpdates: Bool {
    chartView.chartData != nil
  }

  func setChartData(_ data: ChartPresentationData) {
    chartView.chartData = data
  }

  func setActivePointDistance(_ distance: Double) {
    chartView.setSelectedPoint(distance)
  }

  func setMyPositionDistance(_ distance: Double) {
    chartView.myPosition = distance
  }

  func reloadDescription() {
    descriptionCollectionView.reloadData()
  }
}
