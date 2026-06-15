return function(helpers, services)
	local LightningBolt = require(script.Bolt)

	local Lightning = {}

	local function AttachmentFromPosition(Position)
		return {
			WorldPosition = Position,
			WorldAxis = Vector3.new(0, 1, 0),
		}
	end

	function Lightning.Strike(StartPosition, EndPosition, BendFactor, Jaggedness, Thickness, Iterations, Color)
		local StartAttachment = AttachmentFromPosition(StartPosition)
		local EndAttachment = AttachmentFromPosition(EndPosition)
		local Bolt = LightningBolt.new(StartAttachment, EndAttachment, Iterations or 40)

		Bolt.Thickness = Thickness or Bolt.Thickness
		Bolt.MinRadius = 0
		Bolt.MaxRadius = Jaggedness or BendFactor or Bolt.MaxRadius
		Bolt.Color = Color or Bolt.Color
		Bolt:DestroyDissipate(0.35)

		return Bolt
	end

	return Lightning
end
